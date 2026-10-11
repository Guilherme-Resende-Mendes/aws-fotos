# Retoma um job do AzCopy em ciclos: roda $RunMin minutos, pausa $PauseMin para o HD esfriar.
# Se o HD cair, espera ele voltar, esfria $CoolMin minutos e baixa a concorrencia em 4 (minimo $MinConcurrency).
# Criado para o HD 2 Seagate, que trava por timeout depois de horas de leitura continua (SMART: 0 setores ruins).
# Exige az login feito antes.

param(
    [Parameter(Mandatory)][string]$JobId,
    [string]$Serial = '5E1DACF2',
    [string]$Drive = 'D:',
    [string]$Label = 'HD 2',
    [int]$Concurrency = 16,
    [int]$MinConcurrency = 4,
    [int]$RunMin = 50,
    [int]$PauseMin = 10,
    [int]$CoolMin = 20
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:Path = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;' + $env:Path
$env:AZCOPY_AUTO_LOGIN_TYPE = 'AZCLI'

$Repo = Split-Path $PSScriptRoot -Parent
$Log = Join-Path $Repo 'manifests\fila.log'
$Work = Join-Path $env:TEMP 'nanda-upload'
New-Item -ItemType Directory -Force -Path $Work | Out-Null

function Write-Line([string]$Text) {
    $line = '{0}  {1}' -f (Get-Date -Format 'dd/MM HH:mm:ss'), $Text
    Write-Host $line
    Add-Content -LiteralPath $Log -Value $line -Encoding UTF8
}

function Test-Disk {
    $d = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$Drive'"
    return ($d -and $d.VolumeSerialNumber -eq $Serial)
}

function Wait-Disk {
    if (Test-Disk) { return }
    Write-Line "$Label sumiu de $Drive; esperando voltar"
    while (-not (Test-Disk)) { Start-Sleep -Seconds 60 }
    Write-Line "$Label voltou; esfriando $CoolMin min"
    Start-Sleep -Seconds ($CoolMin * 60)
}

$azcopy = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter azcopy.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $azcopy) { throw 'AzCopy nao encontrado.' }

$cycle = 0
$retries = 0
Write-Line "ciclos $Label job $JobId concorrencia $Concurrency, $RunMin min rodando / $PauseMin pausa"

while ($true) {
    Wait-Disk
    $cycle++
    $env:AZCOPY_CONCURRENCY_VALUE = "$Concurrency"
    $out = Join-Path $Work "ciclo-$cycle.out"
    Write-Line "ciclo $cycle inicio, concorrencia $Concurrency"
    $p = Start-Process -FilePath $azcopy -ArgumentList @('jobs', 'resume', $JobId) `
        -NoNewWindow -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"

    if (-not $p.WaitForExit($RunMin * 60 * 1000)) {
        Stop-Process -Id $p.Id -Force
        $p.WaitForExit()
        $last = ((Get-Content -LiteralPath $out -Raw) -split "`r|`n" | Where-Object { $_ -match 'Done' } | Select-Object -Last 1)
        Write-Line "ciclo $cycle pausa $PauseMin min | $last"
        $retries = 0
        Start-Sleep -Seconds ($PauseMin * 60)
        continue
    }

    $text = Get-Content -LiteralPath $out -Raw
    $status = if ($text -match 'Final Job Status: (\S+)') { $Matches[1] } else { 'desconhecido' }
    $failed = if ($text -match 'Number of File Transfers Failed: (\d+)') { [int]$Matches[1] } else { -1 }
    Write-Line "ciclo $cycle terminou: $status, falhas $failed"

    if ($status -eq 'Completed' -or ($status -like 'Completed*' -and $failed -eq 0)) {
        Write-Line "fim $Label"
        break
    }

    if (-not (Test-Disk)) {
        $Concurrency = [Math]::Max($MinConcurrency, $Concurrency - 4)
        Write-Line "$Label caiu no ciclo $cycle; concorrencia baixa para $Concurrency"
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
