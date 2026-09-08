$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$zipPath = Join-Path ([System.IO.Path]::GetTempPath()) ('DovetailMaker2026-' + [guid]::NewGuid().ToString() + '.zip')
$sources = @('DovetailMaker2026', 'dovetail_maker_2026.rb', 'README.md', 'README_EN.md') | ForEach-Object { Join-Path $projectRoot $_ }
Compress-Archive -LiteralPath $sources -DestinationPath $zipPath
$package = Join-Path $dist 'DovetailMaker2026.rbz'
Move-Item -LiteralPath $zipPath -Destination $package -Force
$archive = [System.IO.Compression.ZipFile]::OpenRead($package)
try {
    $names = $archive.Entries.FullName
    foreach ($required in @('dovetail_maker_2026.rb', 'DovetailMaker2026/tail_joints.rb', 'DovetailMaker2026/ui/dialog.html')) {
        if ($names -notcontains $required) { throw "Missing package entry: $required" }
    }
    foreach ($entry in $archive.Entries) {
        if ($entry.FullName.EndsWith('/')) { continue }
        $reader = $entry.Open()
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $packedHash = [BitConverter]::ToString($sha.ComputeHash($reader)).Replace('-', '')
            $sourceHash = (Get-FileHash -LiteralPath (Join-Path $projectRoot $entry.FullName) -Algorithm SHA256).Hash
            if ($packedHash -ne $sourceHash) { throw "Source/package mismatch: $($entry.FullName)" }
        } finally { $reader.Dispose(); $sha.Dispose() }
    }
} finally { $archive.Dispose() }
Write-Output "Verified RBZ: $package"
