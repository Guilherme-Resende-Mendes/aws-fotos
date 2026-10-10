# Sobe o ADATA HV300 (serie DEF527BB) para o Azure Blob Archive.
# Cada pasta de trabalho vai como arquivos soltos, sem zip. O prefixo do blob e a pasta.
# Exige az login feito antes. Nao sobe enquanto o disco nao estiver montado.

param(
    [string]$AccountName = 'ngacervoteste',
    [string]$ResourceGroup = 'nanda-gil-fotos',
    [string]$Container = 'acervo',
    [string]$Location = 'eastus',
    [string]$Serial = 'DEF527BB',
    [switch]$Prepare
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Repo = Split-Path $PSScriptRoot -Parent
$ManifestDir = Join-Path $Repo 'manifests'
New-Item -ItemType Directory -Force -Path $ManifestDir | Out-Null
$Manifest = Join-Path $ManifestDir 'adata-hv300.csv'

function Write-Line([string]$Text) {
    Write-Host ("{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $Text)
}

function Assert-Az {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw 'Azure CLI nao esta no PATH. Abra um terminal novo depois da instalacao.'
    }
    az account show --output none
    if ($LASTEXITCODE -ne 0) { throw 'Sem login na Azure. Rode: az login --use-device-code' }
}

Assert-Az

if ($Prepare) {
    Write-Line "criando grupo $ResourceGroup em $Location"
    az group create --name $ResourceGroup --location $Location --output none
    Write-Line "criando conta $AccountName"
    az storage account create `
        --name $AccountName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --min-tls-version TLS1_2 `
        --output none
    if ($LASTEXITCODE -ne 0) { throw "falha ao criar a conta $AccountName" }
    az storage container create `
        --name $Container `
        --account-name $AccountName `
        --auth-mode login `
        --public-access off `
        --output none
    Write-Line 'conta e container prontos'
}

$disk = Get-CimInstance Win32_LogicalDisk | Where-Object {
    $_.VolumeSerialNumber -eq $Serial -and $_.Size -gt 10GB
} | Select-Object -First 1

if (-not $disk) {
    throw "ADATA serie $Serial nao esta montado. Conecte o HD e rode de novo."
}

$root = $disk.DeviceID + '\'
Write-Line ("disco {0} rotulo={1}" -f $disk.DeviceID, $disk.VolumeName)

$skip = @('$RECYCLE.BIN', 'System Volume Information', '.Spotlight-V100', '.Trashes', '.fseventsd', '.TemporaryItems', '_nanda-upload')
$done = @{}
if (Test-Path -LiteralPath $Manifest) {
    Import-Csv -LiteralPath $Manifest | ForEach-Object { $done[$_.caminho] = $true }
} else {
    'disco,caminho,nome,arquivos' | Set-Content -LiteralPath $Manifest -Encoding UTF8
}

$azcopy = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter azcopy.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $azcopy) { throw 'AzCopy nao encontrado. Instale Microsoft.Azure.AZCopy.10.' }

$env:AZCOPY_AUTO_LOGIN_TYPE = 'AZCLI'
$env:AZCOPY_CONCURRENCY_VALUE = '16'

$source = $root + '*'
$dest = "https://$AccountName.blob.core.windows.net/$Container/adata-hv300"
$exclude = ($skip -join ';')

Write-Line "azcopy $source -> $dest  concorrencia=16  overwrite=false"
& $azcopy copy $source $dest `
    --recursive `
    --block-blob-tier=Archive `
    --overwrite=false `
    --check-length=false `
    "--exclude-path=$exclude" `
    --log-level=ERROR
if ($LASTEXITCODE -ne 0) { throw "azcopy falhou com codigo $LASTEXITCODE" }

$line = 'adata-hv300,"adata-hv300","ADATA HV300",0'
Add-Content -LiteralPath $Manifest -Value $line -Encoding UTF8
Write-Line "fim. manifesto: $Manifest"
