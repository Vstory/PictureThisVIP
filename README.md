# PictureThisVIP

LSPosed / Xposed 模块（libxposed API 102），解锁 **PictureThis（形色/植物识别）** 的 VIP 高级功能。

## 🎯 解锁内容

### VIP 权限（静态解锁）
- ✅ 解锁所有高级功能入口（权限闸门 isPremiumFeatureEligible → true）
- ✅ 全局 VIP 主判断（isVip → true）
- ✅ 历史 VIP / 历史付费标记（isVipInHistory / isPaidInHistory → true）
- ✅ 非试用 / 非假 VIP（isTrial / isFakeVip → false）

### WebView 内嵌页面（v1.1.0+）
- ✅ 修复"连接已断开"：`cms-cache.picture*` 域名资源代拉（绕过 CloudFront TLS 指纹拦截，所有资源 HTTP 200）
- ✅ UA 伪装为 Chrome（WebSettings.setUserAgentString）
- ✅ 修复 `window.updateStartupParams is not a function`（安全包裹调用）

## 目标应用

| 项目 | 值 |
|------|-----|
| 应用名 | PictureThis（植物识别） |
| 包名 | `cn.danatech.xingseus` |
| 版本 | 5.34.0 (versionCode: 5091) |
| 系统 | Android 16 / API 36 |

## 安装

1. 下载 release/ 中的 APK（已签名）
2. 安装 APK
3. LSPosed 中启用模块（作用域自动声明 `cn.danatech.xingseus`，staticScope）
4. 强制停止 PictureThis 后重新打开

## 构建

```bash
./build.sh          # patch: versionCode+1
./build.sh minor    # minor: 次版本+1
./build.sh major    # major: 主版本+1
```

产物：`release/PictureThisVIP_<版本>(<版本号>).apk`（已签名可安装）。build.sh 自动跑 verify.sh（7 项检查）。

> 逆向分析 & Hook 方案见 `dev-project/README.md`；版本历史见 `dev-project/CHANGELOG.md`。

## 已知限制

- 缩略图（shrinkwrap）需手动点击才加载（v2+ 待优化）
- 仍有少量 `updateStartupParams` 残留报错（APP 有另一路调用路径），但不影响页面显示

## 免责声明

仅供学习与个人使用，请自行承担风险。
