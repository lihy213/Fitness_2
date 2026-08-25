param(
    [string]$Target = "",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$sdkRoot = if ($env:DEVECO_SDK_HOME) { $env:DEVECO_SDK_HOME } else { "C:\Program Files\Huawei\DevEco Studio\sdk" }
$hdc = Join-Path $sdkRoot "default\openharmony\toolchains\hdc.exe"
$hvigor = "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat"
$hap = Join-Path $projectRoot "entry\build\default\outputs\default\entry-default-unsigned.hap"

if (!(Test-Path -LiteralPath $hdc)) {
    throw "HDC not found: $hdc. Set DEVECO_SDK_HOME or update the SDK path in this script."
}

if (!$SkipBuild) {
    if (!(Test-Path -LiteralPath $hvigor)) {
        throw "hvigorw not found: $hvigor. Check the DevEco Studio installation path."
    }
    Push-Location $projectRoot
    try {
        $env:HVIGOR_USER_HOME = Join-Path $projectRoot ".hvigor-user"
        $env:JAVA_HOME = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { "C:\Program Files\Huawei\DevEco Studio\jbr" }
        $env:Path = "$env:JAVA_HOME\bin;$env:Path"
        & $hvigor --no-daemon --no-parallel --mode module -p product=default assembleHap
        if ($LASTEXITCODE -ne 0) { throw "HAP build failed with exit code: $LASTEXITCODE" }
    } finally {
        Pop-Location
    }
}

if (!(Test-Path -LiteralPath $hap)) {
    throw "HAP not found: $hap"
}

$targets = @(& $hdc list targets | Where-Object { $_ -and $_ -notmatch "^\s*$" })
if ($Target) {
    $targets = @($targets | Where-Object { $_ -eq $Target })
}
if ($targets.Count -eq 0) {
    throw "No HDC device found. Enable Developer mode and USB debugging on nova 14 ultra, then approve the RSA prompt."
}

if ($targets.Count -gt 1 -and !$Target) {
    Write-Host "Multiple HDC devices found: $($targets -join ', ')" -ForegroundColor Yellow
    throw "Use -Target <serial> to select the nova 14 ultra."
}

$serial = $targets[0]
Write-Host "Install target: $serial"
& $hdc -t $serial install -r $hap
if ($LASTEXITCODE -ne 0) {
    throw "HAP install failed. Configure debug signing in DevEco Studio Project Structure > Signing, then rebuild."
}

& $hdc -t $serial shell aa start -a EntryAbility -b com.lihy213.fitness
if ($LASTEXITCODE -ne 0) { throw "The app was installed but failed to start. Check debug-install permission on the phone." }
Write-Host "LIANKE installed and started."
