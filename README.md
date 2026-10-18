# apk-dist

统一 APK 发布仓库：所有开发 APK 的版本清单与安装包集中存放于此，App 内置升级检查从本仓库拉取更新，实现全应用无线内升级（无需 USB / 重复拷贝）。

## 目录结构

每个应用一个子目录，子目录名即 `APP_ID`（App 端 `UpdateCheckPlugin.APP_ID` 与之对应）：

```
apk-dist/
├── README.md
├── scripts/
│   └── publish.ps1            # 通用发布脚本（多应用共用）
├── <app_id>/
│   ├── version.json           # 版本清单（versionName/versionCode/url/sha256/note）
│   └── <app_id>-vX.Y.Z.apk    # 安装包
└── ...
```

## version.json 约定字段

```json
{
  "versionName": "1.4.28",
  "versionCode": 34,
  "url": "https://raw.githubusercontent.com/<owner>/apk-dist/main/<app_id>/<app_id>-v1.4.28.apk",
  "sha256": "<APK_SHA256 大写>",
  "note": "本次更新说明"
}
```

## App 端接入

- 升级检查：`GET https://raw.githubusercontent.com/jasonmartin201919/apk-dist/main/<app_id>/version.json`
- 版本比对：远端 `versionCode >` 本地 `BuildConfig.VERSION_CODE` 时提示更新
- 整包下载：下载 url 指向的 APK → SHA256 校验 → 拉起系统安装器覆盖安装
- 多应用：每个 App 只需把 `UpdateCheckPlugin.APP_ID` 改成自己的应用 ID 即可复用同一仓库

## 发布流程（一行命令）

```powershell
.\scripts\publish.ps1 -AppId <app_id> -ApkPath <本地APK绝对路径> -VersionName x.y.z -VersionCode n -Note "更新说明"
```

脚本自动完成：复制 APK → 计算 sha256 → 写 version.json → git add/commit/push。

## 已收录应用

| APP_ID | 应用 | 最新版本 | 说明 |
|---|---|---|---|
| reddou-downloader | 红抖下载神器 | 1.4.28 | 小红书/抖音/Instagram 无水印下载 |
