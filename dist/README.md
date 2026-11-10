# 推鞫 · APK 分发

## 下载

| 版本 | 文件 | 大小 |
|---|---|---|
| v0.3 | `tuiju-0.3.apk` | 24.5 KB |

直链：
https://github.com/jasonmartin201919/apk-dist/raw/main/dist/tuiju-0.3.apk

## 安装

1. 手机浏览器打开直链下载
2. 点开安装，提示「未知来源」时允许一次
3. 首次打开先去「设置」填 API 地址、Key、模型

## 版本说明

- **v0.3**（versionCode 2）：修复启动闪退。
  原因是打包时 d8 只编进了 `MainActivity`，内部类 `MainActivity$Bridge`
  与匿名类 `MainActivity$1` 缺失，启动即抛 `NoClassDefFoundError`。
  已改为编译全部 class，并在崩溃时把堆栈直接显示在屏幕上。
- v0.2（versionCode 1）：首个构建，启动即闪退，请勿使用。

## 说明

- 独立运行，不依赖电脑
- 数据只存在本机
- 未配置模型时只做统计速勘，不做判断
