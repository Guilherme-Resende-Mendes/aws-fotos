# Fila: HD 5 (retoma o job), depois HD 1, depois HD 3.
# Arquivos soltos, camada Archive, sem reenviar o que ja existe.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:Path = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;' + $env:Path
$env:AZCOPY_AUTO_LOGIN_TYPE = 'AZCLI'
$env:AZCOPY_CONCURRENCY_VALUE = '16'

$Account = 'ngacervoteste'
$Container = 'acervo'
$JobHd5 = '4c9ea829-322f-3443-5039-aea4a5a55914'
$Repo = Split-Path $PSScriptRoot -Parent
$Log = Join-Path $Repo 'manifests\fila.log'
New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null

function Write-Line([string]$Text) {
    $line = '{0}  {1}' -f (Get-Date -Format 'HH:mm:ss'), $Text
    Write-Host $line
    Add-Content -LiteralPath $Log -Value $line -Encoding UTF8
}

function Find-AzCopy {
    $exe = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter azcopy.exe -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $exe) { throw 'AzCopy nao encontrado.' }
    return $exe
}

function Get-DiskBySerial([string]$Serial) {
    return Get-CimInstance Win32_LogicalDisk | Where-Object {
        $_.VolumeSerialNumber -eq $Serial -and $_.Size -gt 10GB
    } | Select-Object -First 1
}

$azcopy = Find-AzCopy
$exclude = '$RECYCLE.BIN;System Volume Information;.Spotlight-V100;.Trashes;.fseventsd;.TemporaryItems;_nanda-upload;Seagate;Start_Here_Mac.app'
$pattern = 'Start_Here*;Warranty.pdf;Autorun.inf;*.lnk;*.url;bootTel.dat'

function Copy-Disk([string]$Serial, [string]$Prefix, [string]$Label) {
    $disk = Get-DiskBySerial $Serial
    if (-not $disk) { throw "$Label serie $Serial nao esta montado." }
    $source = $disk.DeviceID + '\*'
    $dest = "https://$Account.blob.core.windows.net/$Container/$Prefix"
    Write-Line "inicio $Label $($disk.DeviceID) $($disk.VolumeName) -> $Prefix"
    & $azcopy copy $source $dest `
        --recursive `
        --block-blob-tier=Archive `
        --overwrite=false `
        --check-length=false `
        "--exclude-path=$exclude" `
        "--exclude-pattern=$pattern" `
        --log-level=ERROR
    if ($LASTEXITCODE -ne 0) { throw "$Label falhou com codigo $LASTEXITCODE" }
    Write-Line "fim $Label"
}

$hd5 = Get-DiskBySerial 'DEF527BB'
if (-not $hd5) { throw 'ADATA HV300 nao esta montado.' }
if ($hd5.DeviceID -ne 'D:') { throw "O job do HD 5 espera o ADATA em D:, e ele esta em $($hd5.DeviceID)." }

Write-Line 'retomando HD 5 ADATA HV300'
& $azcopy jobs resume $JobHd5
if ($LASTEXITCODE -ne 0) {
    Write-Line "resume do HD 5 saiu $LASTEXITCODE; tentando copia nova sem reenviar"
    Copy-Disk 'DEF527BB' 'adata-hv300' 'HD 5'
} else {
    Write-Line 'fim HD 5'
}

Copy-Disk '0CCF1441' 'hd-ng-22' 'HD 1'
Copy-Disk 'EE4CF827' 'toshiba-ext' 'HD 3'
Write-Line 'fila concluida'
