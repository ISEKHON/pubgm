# Builds and runs the unit tests with MSVC. Usage: powershell -File server\build.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$vcvars = Get-ChildItem "C:\Program Files\Microsoft Visual Studio" -Recurse -Filter vcvars64.bat -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $vcvars) { throw "vcvars64.bat not found; install the MSVC C++ build tools" }

$out = Join-Path $root 'build'
New-Item -ItemType Directory -Force $out | Out-Null

# Each test has its own main(), so they link as separate executables.
$suites = @(
    @{ name = 'test_bitstream'; srcs = @('src/bitstream.c', 'tests/test_bitstream.c') },
    @{ name = 'test_packet';    srcs = @('src/bitstream.c', 'src/packet.c', 'tests/test_packet.c') },
    @{ name = 'test_sha1';      srcs = @('src/sha1.c', 'tests/test_sha1.c') },
    @{ name = 'test_handshake'; srcs = @('src/bitstream.c', 'src/sha1.c', 'src/handshake.c', 'tests/test_handshake.c') }
)

$failed = 0
foreach ($s in $suites) {
    $missing = $s.srcs | Where-Object { -not (Test-Path (Join-Path $root $_)) }
    if ($missing) { Write-Host "SKIP $($s.name) (missing: $($missing -join ', '))"; continue }
    $srcs = ($s.srcs | ForEach-Object { '"' + (Join-Path $root $_) + '"' }) -join ' '
    # Per-suite object dir, so objects of the same basename cannot collide.
    $objdir = Join-Path $out $s.name
    New-Item -ItemType Directory -Force $objdir | Out-Null
    $exe = Join-Path $out ($s.name + '.exe')
    $inc = Join-Path $root 'include'
    $cmd = '"' + $vcvars.FullName + '" >nul && cl /nologo /W4 /WX /I "' + $inc + '" ' +
           $srcs + ' /Fo"' + $objdir + '\\" /Fe"' + $exe + '"'
    cmd /c $cmd | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BUILD FAILED: $($s.name)"
        cmd /c $cmd
        $failed = 1
        continue
    }
    & $exe
    if ($LASTEXITCODE -ne 0) { $failed = 1 }
}

# Build the server executable (not a test suite).
$srvsrcs = @('src/bitstream.c','src/packet.c','src/sha1.c','src/handshake.c','src/main.c')
$missing = $srvsrcs | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missing) {
    Write-Host "SKIP pubgm_server (missing: $($missing -join ', '))"
} else {
    $srcs = ($srvsrcs | ForEach-Object { '"' + (Join-Path $root $_) + '"' }) -join ' '
    $objdir = Join-Path $out 'pubgm_server'
    New-Item -ItemType Directory -Force $objdir | Out-Null
    $exe = Join-Path $out 'pubgm_server.exe'
    $inc = Join-Path $root 'include'
    $cmd = '"' + $vcvars.FullName + '" >nul && cl /nologo /W4 /WX /I "' + $inc + '" ' +
           $srcs + ' /Fo"' + $objdir + '\\" /Fe"' + $exe + '" /link ws2_32.lib'
    cmd /c $cmd | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host 'BUILD FAILED: pubgm_server'; cmd /c $cmd; $failed = 1 }
    else { Write-Host "built $exe" }
}

if ($failed) { Write-Host 'FAILURES'; exit 1 }
Write-Host 'all suites passed'
exit 0
