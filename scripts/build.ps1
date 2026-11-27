$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Bin = Join-Path $Root "bin"
New-Item -ItemType Directory -Force -Path $Bin | Out-Null

function Find-Fpc {
  $cmd = Get-Command fpc -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  # Reload Machine/User PATH (Chocolatey installs often update Machine only)
  $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [System.Environment]::GetEnvironmentVariable("Path", "User")
  if ($machine -or $user) {
    $env:Path = @($machine, $user, $env:Path) -join ";"
  }
  $cmd = Get-Command fpc -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $candidates = @(
    "C:\tools\freepascal\bin\x86_64-win64\fpc.exe",
    "C:\tools\freepascal\bin\i386-win32\fpc.exe",
    "C:\FPC\3.2.2\bin\x86_64-win64\fpc.exe",
    "C:\FPC\3.2.2\bin\i386-win32\fpc.exe",
    "C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe",
    "C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe"
  )
  foreach ($path in $candidates) {
    if (Test-Path $path) { return $path }
  }
  return $null
}

$fpcExe = Find-Fpc
if (-not $fpcExe) {
  Write-Error "fpc not found on PATH. Install Free Pascal: https://www.freepascal.org/download.html"
}

& $fpcExe -O2 "-Fu$Root\src" "-FE$Bin" "$Root\src\pascalanything.lpr"
if ($LASTEXITCODE -ne 0) {
  Write-Error "fpc failed with exit code $LASTEXITCODE"
}

$exe = Join-Path $Bin "pascalanything.exe"
if (-not (Test-Path $exe)) {
  Write-Error "expected binary missing: $exe"
}
Write-Host "built $exe"

$localBin = Join-Path $env:USERPROFILE ".local\bin"
New-Item -ItemType Directory -Force -Path $localBin | Out-Null
$dest = Join-Path $localBin "pascal-anything.exe"
Copy-Item -Force $exe $dest
Write-Host "installed $dest"
Write-Host "Add $localBin to PATH if needed."
