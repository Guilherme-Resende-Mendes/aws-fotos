# Sobe o HD 2 Seagate Expansion Drive (serie 5E1DACF2) para o Azure Blob Archive.
# Arquivos soltos, disco inteiro, sem reenviar o que ja existe. Exige az login feito antes.

# Concorrencia 32 derrubou o HD do USB em 09/10/2026; 16 rodou estavel.
param(
    [int]$Concurrency = 16
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:Path = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;' + $env:Path
$env:AZCOPY_AUTO_LOGIN_TYPE = 'AZCLI'
$env:AZCOPY_CONCURRENCY_VALUE = "$Concurrency"

$Account = 'ngacervoteste'
$Container = 'acervo'
$Serial = '5E1DACF2'
$Prefix = 'seagate-expansion-drive'
$Label = 'HD 2'
$Repo = Split-Path $PSScriptRoot -Parent
$Log = Join-Path $Repo 'manifests\fila.log'
New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null

function Write-Line([string]$Text) {
    $line = '{0}  {1}' -f (Get-Date -Format 'HH:mm:ss'), $Text
    Write-Host $line
    Add-Content -LiteralPath $Log -Value $line -Encoding UTF8
}

az account show --output none
if ($LASTEXITCODE -ne 0) { throw 'Sem login na Azure. Rode: az login --use-device-code' }

$azcopy = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter azcopy.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $azcopy) { throw 'AzCopy nao encontrado. Instale Microsoft.Azure.AZCopy.10.' }

$disk = Get-CimInstance Win32_LogicalDisk | Where-Object {
    $_.VolumeSerialNumber -eq $Serial -and $_.Size -gt 10GB
} | Select-Object -First 1
if (-not $disk) { throw "$Label serie $Serial nao esta montado." }

$exclude = '$RECYCLE.BIN;System Volume Information;.Spotlight-V100;.Trashes;.fseventsd;.TemporaryItems;_nanda-upload;Seagate;Start_Here_Mac.app'
$pattern = 'Start_Here*;Warranty.pdf;Autorun.inf;*.lnk;*.url;bootTel.dat'
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
