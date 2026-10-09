# Vigia volumes novos e grava um inventario em docs/hds.
# Ignora C: e o HD NG 22, ja documentado. Nao lista nome de cliente.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Repo = Split-Path $PSScriptRoot -Parent
$Docs = Join-Path $Repo 'docs\hds'
$StatePath = Join-Path $PSScriptRoot 'hd-state.json'
New-Item -ItemType Directory -Force -Path $Docs | Out-Null

function Write-Line([string]$Text) {
    $stamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "$stamp  $Text"
}

function Get-State {
    if (-not (Test-Path -LiteralPath $StatePath)) { return @{} }
    $raw = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8
    if (-not $raw.Trim()) { return @{} }
    $obj = $raw | ConvertFrom-Json
    $map = @{}
    foreach ($p in $obj.PSObject.Properties) { $map[$p.Name] = $p.Value }
    return $map
}

function Save-State($Map) {
    $out = @{}
    foreach ($k in $Map.Keys) { $out[$k] = $Map[$k] }
    ($out | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $StatePath -Encoding UTF8
}

function Get-Volumes {
    Get-CimInstance Win32_LogicalDisk | Where-Object {
        $_.DeviceID -ne 'C:' -and $_.Size -gt 10GB -and $_.FileSystem
    }
}

function Slug([string]$Text) {
    $s = $Text.ToLowerInvariant()
    $s = $s -replace '[^a-z0-9]+', '-'
    $s = $s.Trim('-')
    if (-not $s) { $s = 'hd' }
    return $s
}

function Test-MonthName([string]$Name) {
    return $Name -match '^\d{2}\s*-\s*'
}

function Invoke-Inventory($Disk) {
    $letter = $Disk.DeviceID
    $root = "$letter\"
    $label = $Disk.VolumeName
    if (-not $label) { $label = "sem-rotulo-$($Disk.VolumeSerialNumber)" }
    $serial = [string]$Disk.VolumeSerialNumber
    $slug = Slug $label
    $report = Join-Path $Docs "$slug.md"

    Write-Line "HD_DETECTADO $letter `"$label`" serial=$serial"
    Write-Line "inventariando $letter ..."

    $ext = @{}
    $top = @{}
    $files = 0
    $bytes = [int64]0
    $skipped = 0

    $stack = New-Object System.Collections.Generic.Stack[string]
    $stack.Push($root)
    while ($stack.Count -gt 0) {
        $dir = $stack.Pop()
        $relDir = $dir.Substring($root.Length).TrimStart('\')
        $first = if ($relDir) { $relDir.Split('\')[0] } else { '' }
        if ($first -in @('$RECYCLE.BIN', 'System Volume Information')) { continue }
        try {
            foreach ($fs in [System.IO.Directory]::GetFileSystemEntries($dir)) {
                if ([System.IO.Directory]::Exists($fs)) {
                    $stack.Push($fs)
                    continue
                }
                $len = [int64]0
                try { $len = [System.IO.FileInfo]::new($fs).Length } catch { $skipped++; continue }
                $files++
                $bytes += $len
                $e = [System.IO.Path]::GetExtension($fs).ToLowerInvariant()
                if (-not $e) { $e = '(sem ext)' }
                if (-not $ext.ContainsKey($e)) { $ext[$e] = @{ n = 0; b = [int64]0 } }
                $ext[$e].n++
                $ext[$e].b += $len
                $rel = $fs.Substring($root.Length)
                $topName = $rel.Split('\')[0]
                if (-not $top.ContainsKey($topName)) { $top[$topName] = @{ n = 0; b = [int64]0 } }
                $top[$topName].n++
                $top[$topName].b += $len
            }
        } catch {
            $skipped++
        }
    }

    $monthLines = New-Object System.Collections.Generic.List[string]
    $sessionTotal = 0
    Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $topName = $_.Name
        $months = @()
        if (Test-MonthName $topName) { $months = @($_) }
        else {
            $months = @(Get-ChildItem -LiteralPath $_.FullName -Directory -Force -ErrorAction SilentlyContinue | Where-Object { Test-MonthName $_.Name })
        }
        foreach ($m in $months) {
            $sess = @(Get-ChildItem -LiteralPath $m.FullName -Directory -Force -ErrorAction SilentlyContinue)
            $sessionTotal += $sess.Count
            $where = if ($topName -eq $m.Name) { $m.Name } else { "$topName / $($m.Name)" }
            $monthLines.Add("- ${where}: $($sess.Count) sessoes")
        }
    }

    $gb = [math]::Round($Disk.Size / 1GB, 1)
    $free = [math]::Round($Disk.FreeSpace / 1GB, 1)
    $used = [math]::Round($bytes / 1GB, 1)
    $when = Get-Date -Format 'yyyy-MM-dd HH:mm'

    $extRows = ($ext.GetEnumerator() | Sort-Object { $_.Value.b } -Descending | Select-Object -First 12 | ForEach-Object {
        '| `{0}` | {1:N0} | {2:N2} |' -f $_.Key, $_.Value.n, ($_.Value.b / 1GB)
    }) -join "`n"

    $topRows = ($top.GetEnumerator() | Sort-Object { $_.Value.b } -Descending | ForEach-Object {
        '| {0} | {1:N0} | {2:N2} |' -f $_.Key, $_.Value.n, ($_.Value.b / 1GB)
    }) -join "`n"

    $monthsBlock = if ($monthLines.Count) { $monthLines -join "`n" } else { 'Nenhuma pasta de mes no padrao `NN - MES`.' }

    $md = @"
# $label

Inventario automatico em $when. Volume ``$letter``, serie ``$serial``.

| | |
| --- | --- |
| Capacidade | $gb GB |
| Livre | $free GB |
| Arquivos lidos | $($files.ToString('N0')) |
| Volume lido | $used GB |
| Sessoes em pasta de mes | $sessionTotal |
| Falhas de leitura | $skipped |

Nomes de cliente nao entram neste relatorio.

## Pastas na raiz

| Pasta | Arquivos | GB |
| --- | --- | --- |
$topRows

## Extensoes

| Extensao | Arquivos | GB |
| --- | --- | --- |
$extRows

## Sessoes por mes

$monthsBlock

Regra de migracao: o disco sobe inteiro, e no calendario a unidade e a sessao.
"@

    Set-Content -LiteralPath $report -Value $md -Encoding UTF8
    Write-Line "HD_INVENTARIO_OK $letter `"$label`" arquivos=$files gb=$used relatorio=$report"
    return @{
        label          = $label
        letter         = $letter
        inventoriedAt  = $when
        report         = $report
        files          = $files
        gb             = $used
    }
}

$state = Get-State
$presentLast = @{}
Write-Line 'WATCH_ON aguardando HDs. C: ignorado.'

while ($true) {
    try {
        $now = @(Get-Volumes)
        $presentNow = @{}
        foreach ($disk in $now) {
            $serial = [string]$disk.VolumeSerialNumber
            if (-not $serial) { continue }
            $presentNow[$serial] = $disk
            $known = $state.ContainsKey($serial)

            if ($disk.VolumeName -eq 'HD NG 22' -and -not $known) {
                $state[$serial] = @{
                    label         = 'HD NG 22'
                    letter        = $disk.DeviceID
                    inventoriedAt = '2026-10-09'
                    report        = 'docs/hd-ng-22.md'
                    note          = 'inventario manual anterior'
                }
                Save-State $state
                Write-Line "HD_JA_CONHECIDO $($disk.DeviceID) `"HD NG 22`" relatorio=docs/hd-ng-22.md"
                continue
            }

            if (-not $known) {
                try {
                    $state[$serial] = Invoke-Inventory $disk
                    Save-State $state
                } catch {
                    Write-Line "HD_ERRO $($disk.DeviceID) $($_.Exception.Message)"
                }
            } elseif (-not $presentLast.ContainsKey($serial)) {
                Write-Line "HD_RECONECTADO $($disk.DeviceID) `"$($disk.VolumeName)`" ja inventariado"
            }
        }

        foreach ($serial in @($presentLast.Keys)) {
            if ($presentNow.ContainsKey($serial)) { continue }
            $name = $presentLast[$serial].VolumeName
            $letter = $presentLast[$serial].DeviceID
            Write-Line "HD_REMOVIDO $letter `"$name`""
        }
        $presentLast = $presentNow
    } catch {
        Write-Line "HD_ERRO loop $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 5
}
