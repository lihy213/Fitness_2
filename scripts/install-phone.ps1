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
    throw "未找到 HDC：$hdc。请设置 DEVECO_SDK_HOME 或修改脚本中的 SDK 路径。"
}

if (!$SkipBuild) {
    if (!(Test-Path -LiteralPath $hvigor)) {
        throw "未找到 hvigorw：$hvigor。请在 DevEco Studio 安装目录下执行。"
    }
    Push-Location $projectRoot
    try {
        $env:HVIGOR_USER_HOME = Join-Path $projectRoot ".hvigor-user"
        $env:JAVA_HOME = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { "C:\Program Files\Huawei\DevEco Studio\jbr" }
        $env:Path = "$env:JAVA_HOME\bin;$env:Path"
        & $hvigor --no-daemon --no-parallel --mode module -p product=default assembleHap
        if ($LASTEXITCODE -ne 0) { throw "HAP 构建失败，退出码：$LASTEXITCODE" }
    } finally {
        Pop-Location
    }
}

if (!(Test-Path -LiteralPath $hap)) {
    throw "未找到 HAP：$hap"
}

$targets = @(& $hdc list targets | Where-Object { $_ -and $_ -notmatch "^\s*$" })
if ($Target) {
    $targets = @($targets | Where-Object { $_ -eq $Target })
}
if ($targets.Count -eq 0) {
    throw "未发现手机 HDC 设备。请在 nova 14 ultra 开启开发者模式、USB 调试，并在手机上确认 RSA/调试授权后重试。"
}

if ($targets.Count -gt 1 -and !$Target) {
    Write-Host "发现多个 HDC 设备：$($targets -join ', ')" -ForegroundColor Yellow
    throw "请使用 -Target <设备序列号> 指定 nova 14 ultra。"
}

$serial = $targets[0]
Write-Host "安装目标：$serial"
& $hdc -t $serial install -r $hap
if ($LASTEXITCODE -ne 0) {
    throw "HAP 安装失败。真机通常需要在 DevEco Studio 的 Project Structure > Signing 完成调试签名；当前构建产物仍是未签名 HAP。"
}

& $hdc -t $serial shell aa start -a EntryAbility -b com.lihy213.fitness
if ($LASTEXITCODE -ne 0) { throw "应用已安装，但启动失败。请检查手机是否允许调试安装。" }
Write-Host "练刻 LIANKE 已安装并启动。"
