---
AIGC:
    Label: "1"
    ContentProducer: 001191440300708461136T1XGW3
    ProduceID: 429ce989457a6c096ee46fed99d82c62_12f17a9dcb2311f196f9525400248c00
    ReservedCode1: +qSK/QgMefUUMGacxuERPBOMMvMUS/dqVzWAjeuJGDCu8qRUuAOXzR58UrH0gQyfdmMBP9A68+6k+UwZL1Sw74Rm0J43XFc5JP7E9S08g1O9KjO5lWyRHtmYSY3AIPNUMJP5Qga4Y/0dDLkcJhqqEa67mLBC6QuyrYjR+aRctLeP4B8YBiCdmrMZMg8=
    ContentPropagator: 001191440300708461136T1XGW3
    PropagateID: 429ce989457a6c096ee46fed99d82c62_12f17a9dcb2311f196f9525400248c00
    ReservedCode2: +qSK/QgMefUUMGacxuERPBOMMvMUS/dqVzWAjeuJGDCu8qRUuAOXzR58UrH0gQyfdmMBP9A68+6k+UwZL1Sw74Rm0J43XFc5JP7E9S08g1O9KjO5lWyRHtmYSY3AIPNUMJP5Qga4Y/0dDLkcJhqqEa67mLBC6QuyrYjR+aRctLeP4B8YBiCdmrMZMg8=
---

# 统一 APK 发布与内升级接入规则

本文档是「apk-dist 统一发布仓库」的**通用接入规范**。仓库集中存放所有开发 APK 的安装包与版本清单，App 内置升级检查从此仓库拉取更新，实现全应用无线内升级（免 USB、免应用商店）。

适用对象：本账号下所有需要「应用内检查更新 / 整包覆盖安装」的 Android 开发项目。

---

## 1. 仓库结构约定

```
apk-dist/
├── README.md               # 仓库总览（应用接入说明）
├── PUBLISHING.md           # 本文档（发布与接入规则）
├── scripts/publish.ps1     # 通用发布脚本（唯一发布入口）
└── <APP_ID>/               # 每个应用一个子目录，子目录名即 APP_ID
    ├── version.json        # 版本清单（App 端拉取此文件判断更新）
    └── <APP_ID>-vX.Y.Z.apk # 当前最新安装包（发布脚本自动保留最新一份）
```

**APP_ID 命名规则**：全小写字母 + 连字符，与工程名一致（如 `reddou-downloader`、`baize`）。一个应用固定一个 APP_ID，禁止改名（改名会导致旧版本拉不到更新）。

---

## 2. App 端接入（一次性改造）

在目标工程中复用插件库 `com.marvis.videodownloader.plugin.UpdateCheckPlugin`（或等价实现），关键点：

### 2.1 配置常量（3 处）

```kotlin
object UpdateCheckPlugin {
    const val GH_OWNER = "jasonmartin201919"   // 统一发布账号，所有应用一致
    const val GH_REPO  = "apk-dist"            // 统一发布仓库，所有应用一致
    const val APP_ID   = "<你的应用ID>"         // 唯一需要改的地方！
}
```

### 2.2 版本清单获取（多镜像自动回退）

App 按顺序尝试以下镜像拉取 `version.json`，任一成功即停止：

| 优先级 | 镜像 | 格式 |
|---|---|---|
| 1 | GitHub raw 直连 | `https://raw.githubusercontent.com/<owner>/<repo>/main/<APP_ID>/version.json` |
| 2 | jsdelivr CDN | `https://cdn.jsdelivr.net/gh/<owner>/<repo>@main/<APP_ID>/version.json` |
| 3 | gh-proxy 代理 | `https://gh-proxy.com/https://raw.githubusercontent.com/<owner>/<repo>/main/<APP_ID>/version.json` |

> 设计原因：国内网络直连 raw.githubusercontent.com 不稳定，App 内请求常被拦截导致「无法连接更新服务器」。镜像回退保证至少一条链路可达。APK 下载地址同样随成功镜像做对应转换（raw → jsdelivr / gh-proxy 前缀）。

### 2.3 版本比对与覆盖安装

- 版本比对：远端 `versionCode > 本地 BuildConfig.VERSION_CODE` 才提示更新；相等提示已最新；**远端小于本地禁止提示**（防降级）。
- 整包下载：下载 url 指向的 APK → SHA256 校验（与 version.json.sha256 比对，不一致丢弃重下或报错）→ FileProvider + `ACTION_VIEW` 拉起系统安装器覆盖安装。
- **签名一致前提**：覆盖安装要求新旧 APK 使用同一签名。debug 构建使用同一 `debug.keystore` 即可；release 必须固定正式签名，严禁换签名发布（换签名只能走卸载重装，丢失数据）。

---

## 3. 发布新版本（唯一入口：publish.ps1）

```powershell
.\scripts\publish.ps1 `
  -AppId <APP_ID> `
  -ApkPath <编译出的APK绝对路径> `
  -VersionName x.y.z `
  -VersionCode <整数，必须递增> `
  -Note "本次更新说明（显示在更新弹窗）"
```

脚本自动完成：复制 APK → 计算 sha256 → 写 version.json（UTF-8 无 BOM）→ git add/commit/push → 发布完成。

**发布前置检查（必做）**：

| 检查项 | 要求 |
|---|---|
| 版本号 | `versionCode` 必须**严格大于**当前已发布值，禁止降级；`versionName` 随 code 递增 |
| 编译产物 | 先 `assembleDebug`（或 release）编译成功，用 `aapt dump badging` 核对包名/版本无误 |
| 签名 | 与已安装版本一致（见 2.3） |
| 网络 | 本机可访问 GitHub（国内直连不稳定时，脚本 push 可能失败，可重试或走代理） |

**发布后验证（必做）**：

```
# 三条镜像链路任一可达即视为发布成功
1. https://raw.githubusercontent.com/<owner>/<repo>/main/<APP_ID>/version.json
2. https://cdn.jsdelivr.net/gh/<owner>/<repo>@main/<APP_ID>/version.json
3. https://gh-proxy.com/https://raw.githubusercontent.com/<owner>/<repo>/main/<APP_ID>/version.json
```

真机验收：旧版本手机 App 内点「检查更新」→ 弹出版本提示 → 下载 → SHA256 校验 → 覆盖安装 → 版本号变为新值。

---

## 4. 版本规则（强制）

1. **禁止降级**：versionCode 单调递增，任何人不得回退已发布版本号。
2. **禁止覆盖发布**：同一 versionName 只能对应一个 versionCode；改代码必须升版本。
3. **改动即发布**：任何用户可见的功能/修复合入后，必须同步升版本并走发布流程，避免测试包与发布包不一致。
4. **发布即留痕**：version.json 的 note 字段必须写明本次更新内容，作为更新弹窗文案与发布历史。

---

## 5. 故障排查速查

| 现象 | 可能原因 | 处理 |
|---|---|---|
| App 提示「无法连接更新服务器」 | 三条镜像全不可达 / 网络异常 | 检查本机三条镜像是否 200；检查 APP_ID 与仓库目录是否一致 |
| 提示更新但下载失败 | APK 直链失效 / 镜像未同步 | 重新跑 publish.ps1；确认 version.json.url 与文件名一致 |
| 下载后安装失败「应用未安装」 | 签名不一致 | 换回同一 keystore 重新编译发布；或接受卸载重装 |
| 已是最新但实际有新版 | versionCode 比对错误 | 确认远端 versionCode 是否大于本地；确认已推送成功（git log） |
| push 超时/失败 | 国内直连 GitHub 不稳定 | 重试；或临时走 gh-proxy 等代理 push |

---

## 6. 多应用扩展

新增一个应用接入：只需两步——

1. 工程内改 `UpdateCheckPlugin.APP_ID` 为自己的 ID；
2. 发布时用同一 publish.ps1 + 自己的 APP_ID 推送一次，脚本自动创建子目录。

无需改仓库结构、无需改其它应用配置。仓库内各应用相互隔离、互不影响。
*（内容由AI生成，仅供参考）*
