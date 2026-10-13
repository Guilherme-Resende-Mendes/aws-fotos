# Vigia os envios em ciclos e retoma o que parou. Roda a cada $IntervalMin minutos, sem fim.
# Para cada disco da lista, na ordem: se o job ja terminou (Completed*), pula; se o upload-ciclos.ps1 dele
# nao esta rodando e o disco responde na letra do job, abre de novo numa janela minimizada.
# Se o script esta vivo mas o log do AzCopy nao muda ha $StallMin minutos com o disco respondendo,
# fecha o script e o AzCopy e abre de novo. No maximo $MaxDiscos ao mesmo tempo (8 GB de RAM no PC).
# Exige az login feito antes.

param(
    [int]$MaxDiscos = 2,
    [int]$IntervalMin = 5,
    [int]$StallMin = 90,
    [int]$ProbeSec = 30,
    # So vigia estes discos (ex.: -Somente 'HD 1'); vazio vigia a lista toda.
    [string[]]$Somente = @()
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# A letra tem de ser a mesma de quando o job comecou: o AzCopy retoma pelo caminho gravado no job.
$Discos = @(
    @{ Label = 'HD 2'; JobId = '7b782459-0dd8-fe4b-4197-c069ff78a238'; Drive = 'D:'; Serial = '5E1DACF2'; Concurrency = 8; MaxConcurrency = 16 },
    @{ Label = 'HD 1'; JobId = '9103964d-c076-1f48-6a2f-f50336afb55a'; Drive = 'F:'; Serial = '0CCF1441'; Concurrency = 12; MaxConcurrency = 32 },
    @{ Label = 'HD 4'; JobId = '0ea3dd7e-a62c-0d40-7069-20e96279e697'; Drive = 'E:'; Serial = '8E457BBB'; Concurrency = 8 },
    @{ Label = 'HD 6'; JobId = '3cbdba38-8162-714e-6cb6-c6d56cbb196f'; Drive = 'D:'; Serial = '1431744A'; Concurrency = 12; MaxConcurrency = 32 },
    @{ Label = 'HD 8'; JobId = '7fd96eaa-6701-094f-50a8-8a8ecbf8eb71'; Drive = 'E:'; Serial = '6793ED1D'; Concurrency = 12; MaxConcurrency = 24 }
)
# Por -File a lista chega como um texto so ('HD 2,HD 8').
$Somente = @($Somente | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($Somente.Count) { $Discos = @($Discos | Where-Object { $Somente -contains $_.Label }) }

# Mantem o PC acordado enquanto o vigia roda (mesmo pedido do upload-ciclos.ps1; nao muda o plano de energia).
Add-Type -Namespace Nanda -Name Energia -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$null = [Nanda.Energia]::SetThreadExecutionState([uint32]'0x80000003')
# So o pedido continuo nao bastou: o PC entrou em espera as 00:03 de 13/10/2026 com tudo rodando.
# Renovar a cada 30 s zera tambem o contador de inatividade de sistema e tela.
function Stay-Awake {
    $null = [Nanda.Energia]::SetThreadExecutionState([uint32]'0x00000003')  # zera os contadores (sistema e tela)
    $null = [Nanda.Energia]::SetThreadExecutionState([uint32]'0x80000003')  # e mantem o pedido continuo
}

$Repo = Split-Path $PSScriptRoot -Parent
$Log = Join-Path $Repo 'manifests\fila.log'
$Ciclos = Join-Path $PSScriptRoot 'upload-ciclos.ps1'

function Write-Line([string]$Text) {
    $line = '{0}  vigia: {1}' -f (Get-Date -Format 'dd/MM HH:mm:ss'), $Text
    Write-Host $line
    Add-Content -LiteralPath $Log -Value $line -Encoding UTF8
}

$azcopy = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter azcopy.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $azcopy) { throw 'AzCopy nao encontrado.' }

# Mesmo teste do upload-ciclos.ps1: em outro processo e com prazo, porque um HD travado congela o WMI.
$Probes = @{}
function Test-Disk($d) {
    $old = $Probes[$d.Label]
    if ($old -and -not $old.HasExited) { return $false }
    $code = "`$x = Get-CimInstance Win32_LogicalDisk -Filter `"DeviceID='$($d.Drive)'`"; " +
        "if (-not `$x -or `$x.VolumeSerialNumber -ne '$($d.Serial)') { exit 1 }; " +
        "`$null = [IO.Directory]::GetFileSystemEntries('$($d.Drive)\'); exit 0"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
    $p = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -PassThru `
        -ArgumentList @('-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded)
    $null = $p.Handle
    $Probes[$d.Label] = $p
    if ($p.WaitForExit($ProbeSec * 1000)) { return ($p.ExitCode -eq 0) }
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    return $false
}

function Get-JobStatus($d) {
    $text = (& $azcopy jobs show $d.JobId 2>&1) -join "`n"
    if ($text -match 'Final Job Status: (\S+)') { return $Matches[1] }
    return 'desconhecido'
}

function Get-Runner($d) {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
        # Pelo job ou pela serie do disco: um envio aberto a mao com -Prefix ainda nao tem o job na linha de comando.
        Where-Object { $_.CommandLine -match 'upload-ciclos\.ps1' -and ($_.CommandLine -match $d.JobId -or $_.CommandLine -match $d.Serial) } |
        Select-Object -First 1
}

function Start-Runner($d) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$Ciclos`"",
        '-JobId', $d.JobId, '-Drive', $d.Drive, '-Serial', $d.Serial,
        '-Label', "`"$($d.Label)`"", '-Concurrency', "$($d.Concurrency)")
    if ($d.MaxConcurrency) { $argList += @('-MaxConcurrency', "$($d.MaxConcurrency)") }
    $p = Start-Process -FilePath 'powershell.exe' -WindowStyle Minimized -PassThru -ArgumentList $argList
    Write-Line "$($d.Label) parado; retomado o job $($d.JobId) (processo $($p.Id))"
}

Write-Line "inicio, no maximo $MaxDiscos discos, checagem a cada $IntervalMin min"
$done = @{}
while ($true) {
    $running = 0
    $waiting = @()
    foreach ($d in $Discos) {
        if ($done[$d.Label]) { continue }
        $runner = Get-Runner $d
        if ($runner) {
            $running++
            $jobLog = Join-Path $env:USERPROFILE ".azcopy\$($d.JobId).log"
            $idle = if (Test-Path -LiteralPath $jobLog) { ((Get-Date) - (Get-Item -LiteralPath $jobLog).LastWriteTime).TotalMinutes } else { 0 }
            if ($idle -gt $StallMin -and (Test-Disk $d)) {
                Write-Line "$($d.Label) sem progresso ha $([int]$idle) min com o disco respondendo; reiniciando"
                & taskkill.exe /PID $runner.ProcessId /T /F | Out-Null
                $running--
                $waiting += $d
            }
            continue
        }
        $status = Get-JobStatus $d
        if ($status -like 'Completed*') {
            $done[$d.Label] = $true
            Write-Line "$($d.Label) job terminou ($status); se houve falhas de nome, rodar upload-nomes-invalidos.ps1"
            continue
        }
        $waiting += $d
    }
    foreach ($d in $waiting) {
        if ($running -ge $MaxDiscos) { break }
        if (-not (Test-Disk $d)) { continue }
        Start-Runner $d
        $running++
    }
    if ($done.Count -eq $Discos.Count) { Write-Line 'todos os jobs terminaram; fim'; break }
    for ($s = 0; $s -lt $IntervalMin * 60; $s += 30) { Stay-Awake; Start-Sleep -Seconds 30 }
}
