# Sobe um HD em ciclos: roda $RunMin minutos, pausa $PauseMin para o HD esfriar.
# Com -JobId retoma esse job; sem ele, o primeiro ciclo comeca uma copia do disco inteiro para -Prefix
# (sem reenviar o que ja existe) e os seguintes retomam o job criado.
# Se o HD cair, espera ele voltar, esfria $CoolMin minutos e baixa a concorrencia em 4 (minimo $MinConcurrency).
# Criado para o HD 2 Seagate, que trava por timeout depois de horas de leitura continua (SMART: 0 setores ruins).
# Exige az login feito antes.

param(
    [string]$JobId,
    [string]$Prefix,
    [string]$Account = 'ngacervoteste',
    [string]$Container = 'acervo',
    [string]$Serial = '5E1DACF2',
    [string]$Drive = 'D:',
    [string]$Label = 'HD 2',
    [int]$Concurrency = 16,
    [int]$MinConcurrency = 4,
    # Com -MaxConcurrency, cada ciclo que fecha sem queda e com no maximo $MaxNewFailed falhas novas
    # sobe a concorrencia em $StepUp. Se o HD cair, o teto passa a ser a concorrencia que derrubou menos 4.
    [int]$MaxConcurrency = 0,
    [int]$StepUp = 4,
    [int]$MaxNewFailed = 50,
    [int]$RunMin = 50,
    [int]$PauseMin = 10,
    [int]$CoolMin = 20,
    [int]$ProbeSec = 30,
    [double]$BufferGB = 1
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:Path = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;' + $env:Path
$env:AZCOPY_AUTO_LOGIN_TYPE = 'AZCLI'
# Teto de memoria do AzCopy. Sem ele, dois ou tres discos ao mesmo tempo esgotaram os 8 GB do PC
# e o AzCopy fechou com "out of memory" em 10/10/2026.
$env:AZCOPY_BUFFER_GB = "$BufferGB"

# Pede ao Windows para nao entrar em espera nem apagar a tela enquanto o script roda, como um player de video.
# Sem isso o PC dormiu de 01:00 a 08:56 em 11/10/2026 e o envio ficou parado. Vale ate o script fechar;
# nao muda o plano de energia. Fechar a tampa do notebook ainda poe o PC para dormir.
Add-Type -Namespace Nanda -Name Energia -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
# ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
$null = [Nanda.Energia]::SetThreadExecutionState([uint32]'0x80000003')

$Repo = Split-Path $PSScriptRoot -Parent
$Log = Join-Path $Repo 'manifests\fila.log'
$Work = Join-Path $env:TEMP 'nanda-upload'
New-Item -ItemType Directory -Force -Path $Work | Out-Null

function Write-Line([string]$Text) {
    $line = '{0}  {1}' -f (Get-Date -Format 'dd/MM HH:mm:ss'), $Text
    Write-Host $line
    Add-Content -LiteralPath $Log -Value $line -Encoding UTF8
}

# Consulta o disco em outro processo, com prazo de $ProbeSec segundos. Um HD travado no USB congela
# a leitura e o WMI; consultado aqui dentro, prendia o script junto (HD 2, 10/10/2026 23:26).
# Enquanto uma consulta travada nao termina, nao abre outra, para nao acumular processos presos.
$script:Probe = $null
function Test-Disk {
    if ($script:Probe -and -not $script:Probe.HasExited) { return $false }
    $code = "`$d = Get-CimInstance Win32_LogicalDisk -Filter `"DeviceID='$Drive'`"; " +
        "if (-not `$d -or `$d.VolumeSerialNumber -ne '$Serial') { exit 1 }; " +
        "`$null = [IO.Directory]::GetFileSystemEntries('$Drive\'); exit 0"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
    $script:Probe = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -PassThru `
        -ArgumentList @('-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded)
    $null = $script:Probe.Handle
    if ($script:Probe.WaitForExit($ProbeSec * 1000)) { return ($script:Probe.ExitCode -eq 0) }
    Stop-Process -Id $script:Probe.Id -Force -ErrorAction SilentlyContinue
    return $false
}

function Wait-Disk {
    if (Test-Disk) { return }
    Write-Line "$Label sumiu de $Drive ou nao responde; esperando voltar"
    while (-not (Test-Disk)) { Start-Sleep -Seconds 60 }
    Write-Line "$Label voltou; esfriando $CoolMin min"
    Start-Sleep -Seconds ($CoolMin * 60)
}

$azcopy = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter azcopy.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $azcopy) { throw 'AzCopy nao encontrado.' }
if (-not $JobId -and -not $Prefix) { throw 'Passe -JobId para retomar ou -Prefix para comecar.' }

$exclude = '$RECYCLE.BIN;System Volume Information;.Spotlight-V100;.Trashes;.fseventsd;.TemporaryItems;_nanda-upload;Seagate;Start_Here_Mac.app'
$pattern = 'Start_Here*;Warranty.pdf;Autorun.inf;*.lnk;*.url;bootTel.dat'
$copyArgs = @('copy', "$Drive\*", "https://$Account.blob.core.windows.net/$Container/$Prefix",
    '--recursive', '--block-blob-tier=Archive', '--overwrite=false', '--check-length=false',
    "`"--exclude-path=$exclude`"", "`"--exclude-pattern=$pattern`"", '--log-level=ERROR')
$tag = if ($Prefix) { $Prefix } else { $JobId.Substring(0, 8) }

$cycle = 0
$retries = 0
$prevFailed = $null
$what = if ($JobId) { "job $JobId" } else { "copia nova -> $Prefix" }
Write-Line "ciclos $Label $what concorrencia $Concurrency, $RunMin min rodando / $PauseMin pausa"

$p = $null
while ($true) {
    Wait-Disk
    if ($p -and -not $p.HasExited) {
        Write-Line "$Label esperando o AzCopy do ciclo $cycle fechar antes de retomar"
        $p.WaitForExit()
    }
    $cycle++
    $env:AZCOPY_CONCURRENCY_VALUE = "$Concurrency"
    $out = Join-Path $Work "$tag-ciclo-$cycle.out"
    Write-Line "$Label ciclo $cycle inicio, concorrencia $Concurrency"
    $azArgs = if ($JobId) { @('jobs', 'resume', $JobId) } else { $copyArgs }
    $p = Start-Process -FilePath $azcopy -ArgumentList $azArgs `
        -NoNewWindow -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"

    $started = Get-Date
    if (-not $JobId) {
        while (-not $JobId -and -not $p.HasExited -and ((Get-Date) - $started).TotalSeconds -lt 300) {
            Start-Sleep -Seconds 5
            if ((Get-Content -LiteralPath $out -Raw) -match 'Job (\S+) has started') { $JobId = $Matches[1] }
        }
        if (-not $JobId -and (Get-Content -LiteralPath $out -Raw) -match 'Job (\S+) has started') { $JobId = $Matches[1] }
        if (-not $JobId) { if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }; throw "$Label sem id de job; veja $out" }
        Write-Line "$Label job $JobId"
    }
    $left = [Math]::Max(0, $RunMin * 60 - ((Get-Date) - $started).TotalSeconds)
    $finished = $p.WaitForExit([int]($left * 1000))
    if (-not $finished) {
        Stop-Process -Id $p.Id -Force
        # Com o HD travado, o AzCopy pode demorar a fechar; nao espera para sempre aqui.
        if (-not $p.WaitForExit(120000)) { Write-Line "$Label AzCopy nao fechou em 2 min; HD provavelmente travado" }
        $last = ((Get-Content -LiteralPath $out -Raw) -split "`r|`n" | Where-Object { $_ -match 'Done' } | Select-Object -Last 1)
        Write-Line "$Label ciclo $cycle pausa $PauseMin min | $last"
        $retries = 0
        $nowFailed = if ($last -match '(\d+) Failed') { [int]$Matches[1] } else { -1 }
        if (-not (Test-Disk)) {
            # Caiu durante o ciclo e o AzCopy seguiu aberto ate o fim do tempo.
            $Concurrency = [Math]::Max($MinConcurrency, $Concurrency - 4)
            if ($MaxConcurrency -gt $Concurrency) { $MaxConcurrency = $Concurrency }
            $nowFailed = $null
            Write-Line "$Label caiu no ciclo $cycle; concorrencia baixa para $Concurrency e esse vira o teto"
        } elseif ($MaxConcurrency -gt $Concurrency -and $nowFailed -ge 0) {
            $newFailed = if ($null -ne $prevFailed) { $nowFailed - $prevFailed } else { 0 }
            if ($newFailed -le $MaxNewFailed) {
                $Concurrency = [Math]::Min($MaxConcurrency, $Concurrency + $StepUp)
                Write-Line "$Label ciclo $cycle sem queda ($newFailed falhas novas); concorrencia sobe para $Concurrency"
            } else {
                Write-Line "$Label ciclo $cycle com $newFailed falhas novas; concorrencia fica em $Concurrency"
            }
        }
        $prevFailed = $nowFailed
        Start-Sleep -Seconds ($PauseMin * 60)
        continue
    }

    $text = Get-Content -LiteralPath $out -Raw
    $status = if ($text -match 'Final Job Status: (\S+)') { $Matches[1] } else { 'desconhecido' }
    $failed = if ($text -match 'Number of File Transfers Failed: (\d+)') { [int]$Matches[1] } else { -1 }
    $why = ''
    if ($status -eq 'desconhecido') {
        $err = Get-Content -LiteralPath "$out.err" -Raw -ErrorAction SilentlyContinue
        if ($err -match 'out of memory') { $why = ' (AzCopy sem memoria)' }
        elseif ($text -match 'failed to perform [^\r\n]{0,160}') { $why = " ($($Matches[0]))" }
    }
    Write-Line "$Label ciclo $cycle terminou: $status, falhas $failed$why"

    if ($status -eq 'Completed' -or ($status -like 'Completed*' -and $failed -eq 0)) {
        Write-Line "fim $Label"
        break
    }

    if (-not (Test-Disk)) {
        $Concurrency = [Math]::Max($MinConcurrency, $Concurrency - 4)
        if ($MaxConcurrency -gt $Concurrency) { $MaxConcurrency = $Concurrency }
        $prevFailed = $null
        Write-Line "$Label caiu no ciclo $cycle; concorrencia baixa para $Concurrency e esse vira o teto"
        continue
    }

    # Disco presente e ainda com falhas: tenta de novo duas vezes, depois para para alguem olhar.
    $retries++
    if ($retries -gt 2) {
        Write-Line "${Label}: $failed falhas persistem com o disco montado; parando. Veja $out e C:\Users\$env:USERNAME\.azcopy\$JobId.log"
        exit 1
    }
    Write-Line "reenviando falhas (tentativa $retries) depois de $PauseMin min"
    Start-Sleep -Seconds ($PauseMin * 60)
}
