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
    [int]$ProbeSec = 30
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# A letra tem de ser a mesma de quando o job comecou: o AzCopy retoma pelo caminho gravado no job.
$Discos = @(
    @{ Label = 'HD 2'; JobId = '7b782459-0dd8-fe4b-4197-c069ff78a238'; Drive = 'D:'; Serial = '5E1DACF2'; Concurrency = 12 },
    @{ Label = 'HD 1'; JobId = '9103964d-c076-1f48-6a2f-f50336afb55a'; Drive = 'F:'; Serial = '0CCF1441'; Concurrency = 8 },
    @{ Label = 'HD 4'; JobId = '0ea3dd7e-a62c-0d40-7069-20e96279e697'; Drive = 'E:'; Serial = '8E457BBB'; Concurrency = 8 }
)

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
        Where-Object { $_.CommandLine -match 'upload-ciclos\.ps1' -and $_.CommandLine -match $d.JobId } |
        Select-Object -First 1
}

function Start-Runner($d) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$Ciclos`"",
        '-JobId', $d.JobId, '-Drive', $d.Drive, '-Serial', $d.Serial,
        '-Label', "`"$($d.Label)`"", '-Concurrency', "$($d.Concurrency)")
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
    Start-Sleep -Seconds ($IntervalMin * 60)
}
