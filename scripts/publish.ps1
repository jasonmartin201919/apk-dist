param(
    [Parameter(Mandatory = $true)][string]$AppId,
    [Parameter(Mandatory = $true)][string]$ApkPath,
    [Parameter(Mandatory = $true)][string]$VersionName,
    [Parameter(Mandatory = $true)][int]$VersionCode,
    [Parameter(Mandatory = $true)][string]$Note,
    [string]$Owner = "jasonmartin201919"
)

# 统一 APK 发布脚本：复制 APK -> 算 sha256 -> 写 version.json -> git 提交推送
# 用法示例：
#   .\scripts\publish.ps1 -AppId reddou-downloader -ApkPath C:\path\app-debug.apk -VersionName 1.4.28 -VersionCode 34 -Note "新增插件库"

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $repoRoot $AppId

# 1. 校验 APK
if (-not (Test-Path $ApkPath)) { throw "APK 不存在: $ApkPath" }
$apkName = "$AppId-v$VersionName.apk"
$destApk = Join-Path $appDir $apkName
New-Item -ItemType Directory -Path $appDir -Force | Out-Null

# 2. 复制 APK（新版本覆盖旧安装包，保留最新一个）
Get-ChildItem $appDir -Filter "*.apk" -ErrorAction SilentlyContinue | Remove-Item -Force
Copy-Item $ApkPath $destApk -Force
Write-Host "[1/5] APK 已复制到 $destApk"

# 3. 计算 sha256
$sha256 = (Get-FileHash $destApk -Algorithm SHA256).Hash
Write-Host "[2/5] SHA256 = $sha256"

# 4. 写 version.json（UTF-8 无 BOM）
$url = "https://raw.githubusercontent.com/$Owner/$($(Split-Path $repoRoot -Leaf))/main/$AppId/$apkName"
$json = @{
    versionName = $VersionName
    versionCode = $VersionCode
    url = $url
    sha256 = $sha256
    note = $Note
} | ConvertTo-Json
$versionJson = Join-Path $appDir "version.json"
[System.IO.File]::WriteAllText($versionJson, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "[3/5] version.json 已写入 $versionJson"
Write-Host "      url = $url"

# 5. git 提交推送
Set-Location $repoRoot
if (-not (Test-Path ".git")) {
    git init -b main | Out-Null
}
git add -A
git commit -m "publish $AppId v$VersionName (code $VersionCode)" | Out-Null
Write-Host "[4/5] git commit 完成"
git push origin main 2>&1 | Out-Host
Write-Host "[5/5] 发布完成: $AppId v$VersionName"
