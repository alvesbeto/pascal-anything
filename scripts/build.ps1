$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Bin = Join-Path $Root "bin"
New-Item -ItemType Directory -Force -Path $Bin | Out-Null

$fpc = Get-Command fpc -ErrorAction SilentlyContinue
if (-not $fpc) {
  Write-Error "fpc not found on PATH. Install Free Pascal: https://www.freepascal.org/download.html"
}

& fpc -O2 "-Fu$Root\src" "-FE$Bin" "$Root\src\pascalanything.lpr"
$exe = Join-Path $Bin "pascalanything.exe"
Write-Host "built $exe"

$localBin = Join-Path $env:USERPROFILE ".local\bin"
New-Item -ItemType Directory -Force -Path $localBin | Out-Null
$dest = Join-Path $localBin "pascal-anything.exe"
Copy-Item -Force $exe $dest
Write-Host "installed $dest"
Write-Host "Add $localBin to PATH if needed."
