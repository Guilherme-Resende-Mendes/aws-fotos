# Sobe os arquivos com nome que o Azure Blob nao aceita: caractere de controle (U+0081 nos arquivos
# recuperados de "Resultado de Digitalizacao Profunda") ou trecho terminado em ponto.
# Nao mexe no HD: copia cada um para uma pasta temporaria com o nome trocado, caractere de controle vira
# "{U+0081}" e ponto final ganha "_" (U+0081 "_267." U+0081 -> "{U+0081}_267.{U+0081}"),
# sobe essa pasta para o mesmo prefixo e grava a troca em manifests\<prefixo>-nomes-trocados.csv.
# Rodar depois do envio principal do disco. Exige az login feito antes.

param(
    [string]$Serial = '5E1DACF2',
    [string]$Drive = 'D:',
    [string]$Prefix = 'seagate-expansion-drive',
    [string]$Label = 'HD 2',
    [string]$Account = 'ngacervoteste',
    [string]$Container = 'acervo',
    [int]$Concurrency = 8
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:Path = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;' + $env:Path
$env:AZCOPY_AUTO_LOGIN_TYPE = 'AZCLI'
$env:AZCOPY_CONCURRENCY_VALUE = "$Concurrency"

$Repo = Split-Path $PSScriptRoot -Parent
$Log = Join-Path $Repo 'manifests\fila.log'
$Map = Join-Path $Repo "manifests\$Prefix-nomes-trocados.csv"
$Stage = Join-Path $env:TEMP "nanda-ponto\$Prefix"

function Write-Line([string]$Text) {
    $line = '{0}  {1}' -f (Get-Date -Format 'dd/MM HH:mm:ss'), $Text
    Write-Host $line
    Add-Content -LiteralPath $Log -Value $line -Encoding UTF8
}

$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$Drive'"
if (-not $disk -or $disk.VolumeSerialNumber -ne $Serial) { throw "$Label serie $Serial nao esta em $Drive." }

$azcopy = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter azcopy.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $azcopy) { throw 'AzCopy nao encontrado.' }

# O prefixo \\?\ impede o Windows de cortar o ponto final dos nomes.
$root = "\\?\$Drive\"
$skip = @('$RECYCLE.BIN', 'System Volume Information', '.Spotlight-V100', '.Trashes', '.fseventsd', '.TemporaryItems', '_nanda-upload', 'Seagate', 'Start_Here_Mac.app')

$control = '[\u0000-\u001F\u007F-\u009F]'

function Test-BadSegment([string]$Seg) { return ($Seg -match $control -or $Seg.EndsWith('.')) }

function ConvertTo-SafeSegment([string]$Seg) {
    $s = [regex]::Replace($Seg, $control, { param($m) '{U+' + ('{0:X4}' -f [int][char]$m.Value) + '}' })
    if ($s.EndsWith('.')) { $s += '_' }
    return $s
}

function Get-BadFiles([string]$Dir, [bool]$Top) {
    try { $entries = [System.IO.Directory]::GetFileSystemEntries($Dir) } catch { Write-Line "sem acesso: $Dir"; return }
    foreach ($e in $entries) {
        $name = [System.IO.Path]::GetFileName($e)
        if ($Top -and $skip -contains $name) { continue }
        if ([System.IO.Directory]::Exists($e)) { Get-BadFiles $e $false }
        elseif ($e.Substring($root.Length) -split '\\' | Where-Object { Test-BadSegment $_ }) { $e }
    }
}

Write-Line "$Label procurando nomes invalidos para o Azure"
$files = @(Get-BadFiles $root $true)
Write-Line "$Label $($files.Count) arquivos com nome invalido"
if ($files.Count -eq 0) { return }

if (Test-Path -LiteralPath $Stage) { Remove-Item -LiteralPath $Stage -Recurse -Force }
'original,enviado_como' | Set-Content -LiteralPath $Map -Encoding UTF8
$bytes = 0
foreach ($f in $files) {
    $rel = $f.Substring($root.Length)
    $new = ($rel -split '\\' | ForEach-Object { ConvertTo-SafeSegment $_ }) -join '\'
    $dest = "\\?\" + (Join-Path $Stage $new)
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dest)) | Out-Null
    [System.IO.File]::Copy($f, $dest, $true)
    $bytes += (New-Object System.IO.FileInfo $f).Length
    ('"{0}","{1}"' -f ($rel -replace '\\', '/' -replace '"', '""'), ($new -replace '\\', '/' -replace '"', '""')) |
        Add-Content -LiteralPath $Map -Encoding UTF8
}
Write-Line ("$Label copiados {0} arquivos ({1:N2} GB) para a pasta temporaria" -f $files.Count, ($bytes / 1GB))

$dest = "https://$Account.blob.core.windows.net/$Container/$Prefix"
& $azcopy copy "$Stage\*" $dest `
    --recursive `
    --block-blob-tier=Archive `
    --overwrite=false `
    --log-level=ERROR
if ($LASTEXITCODE -ne 0) { throw "$Label nomes trocados falhou com codigo $LASTEXITCODE; pasta temporaria mantida em $Stage" }

Remove-Item -LiteralPath $Stage -Recurse -Force
Write-Line "fim $Label nomes trocados; lista em manifests\$Prefix-nomes-trocados.csv"
