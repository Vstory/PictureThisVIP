package com.hook.picturethis.vip;

import io.github.libxposed.api.XposedInterface;
import io.github.libxposed.api.XposedModule;
import io.github.libxposed.api.XposedModuleInterface;

import java.lang.reflect.Method;

/**
 * PictureThis VIP Unlock 模块 (API 102) — v2
 * 目标: cn.danatech.xingseus (PictureThis)
 *
 * 功能:
 *   v1: VIP模拟 + 权限闸门绕过
 *   v2: + WebView 代拉 (shouldInterceptRequest 绕 CloudFront TLS 拦截)
 *       + UA 伪装 (loadUrl 时 setUserAgentString)
 *       + updateStartupParams 安全包裹 (evaluateJavascript 改写)
 *
 * 已验证 hook 方案 (Aide Frida v15):
 *   1. CheckPointManager.isPremiumFeatureEligible → true
 *   2. VipInfo.isVip/isVipInHistory/isPaidInHistory → true
 *   3. VipInfo.isTrial → false
 *   4. GLMPAccount.isVip → true
 *   5. GLMPAccount.isTrial/isFakeVip → false
 *   6. AppContext.isVip → true
 *   7. WebViewClientProxy.shouldInterceptRequest → 代拉 cms-cache
 *   8. WebView.loadUrl → 设 Chrome UA
 *   9. JsbWebView.evaluateJavascript → 安全包裹 updateStartupParams
 */
public class MainHook extends XposedModule {

    private ClassLoader mAppClassLoader;

    public MainHook() {
        super();
    }

    // ── 生命周期 ──────────────────────────────────────────

    @Override
    public void onModuleLoaded(XposedModuleInterface.ModuleLoadedParam param) {
        log(4, "PictureThisVIP", "api102 module loaded");
    }

    @Override
    public void onPackageReady(XposedModuleInterface.PackageReadyParam param) {
        ClassLoader cl = param.getClassLoader();
        mAppClassLoader = cl;
        installHooks(cl);
        log(4, "PictureThisVIP", "hooks installed");
    }

    @Override
    public boolean onHotReloading(XposedModuleInterface.HotReloadingParam param) {
        return true;
    }

    @Override
    public void onHotReloaded(XposedModuleInterface.HotReloadedParam param) {
        ClassLoader cl = null;
        var oldHandles = param.getOldHookHandles();
        if (!oldHandles.isEmpty()) {
            var handle = (XposedInterface.HookHandle) oldHandles.get(0);
            cl = handle.getExecutable().getDeclaringClass().getClassLoader();
        }
        for (var handle : oldHandles) {
            ((XposedInterface.HookHandle) handle).unhook();
        }
        if (cl == null) cl = mAppClassLoader;
        if (cl == null) return;
        installHooks(cl);
        log(4, "PictureThisVIP", "hot reloaded, hooks reinstalled");
    }

    // ── Hook 安装 ─────────────────────────────────────────

    private void installHooks(ClassLoader cl) {
        var trueHooker = new TrueHooker();
        var falseHooker = new FalseHooker();
        var webViewInterceptor = new WebViewInterceptor();
        var uaLoadUrlHooker = new UALoadUrlHooker();
        var evalJSHooker = new EvalJSHooker();

        // 1. CheckPointManager.isPremiumFeatureEligible → true
        hookMethod(cl, "com.glority.android.common.manager.CheckPointManager",
                "isPremiumFeatureEligible", trueHooker);

        // 2. VipInfo.isVip → true / isTrial → false / isVipInHistory → true / isPaidInHistory → true
        String vipInfoCls = "com.glority.component.generatedAPI.kotlinAPI.vip.VipInfo";
        hookMethod(cl, vipInfoCls, "isVip", trueHooker);
        hookMethod(cl, vipInfoCls, "isTrial", falseHooker);
        hookMethod(cl, vipInfoCls, "isVipInHistory", trueHooker);
        hookMethod(cl, vipInfoCls, "isPaidInHistory", trueHooker);

        // 3. GLMPAccount.isVip → true / isTrial → false / isFakeVip → false
        String glmpCls = "com.glority.android.glmp.GLMPAccount";
        hookMethod(cl, glmpCls, "isVip", trueHooker);
        hookMethod(cl, glmpCls, "isTrial", falseHooker);
        hookMethod(cl, glmpCls, "isFakeVip", falseHooker);

        // 4. AppContext.isVip → true
        hookMethod(cl, "com.glority.android.core.app.AppContext", "isVip", trueHooker);

        // 5. WebViewClientProxy.shouldInterceptRequest(WebView, WebResourceRequest) → 代拉
        hookMethodWithTypes(cl, "com.glority.base.widget.webview.WebViewClientProxy",
                "shouldInterceptRequest",
                new Class[]{android.webkit.WebView.class, android.webkit.WebResourceRequest.class},
                webViewInterceptor);

        // 6. WebView.loadUrl(String) → 设 Chrome UA
        hookMethodWithTypes(cl, "android.webkit.WebView", "loadUrl",
                new Class[]{String.class}, uaLoadUrlHooker);

        // 7. JsbWebView.evaluateJavascript(String, ValueCallback) → updateStartupParams 安全包裹
        hookMethodWithTypes(cl, "com.example.glwebview.JsbWebView",
                "evaluateJavascript",
                new Class[]{String.class, android.webkit.ValueCallback.class},
                evalJSHooker);
    }

    // ── 通用 hook 辅助 ────────────────────────────────────

    /** hook 无参方法 */
    private void hookMethod(ClassLoader cl, String className, String methodName,
                            XposedInterface.Hooker hooker) {
        try {
            Class<?> clazz = Class.forName(className, false, cl);
            Method method = clazz.getDeclaredMethod(methodName);
            hook(method)
                    .setExceptionMode(XposedInterface.ExceptionMode.PROTECTIVE)
                    .intercept(hooker);
        } catch (Throwable ignored) {
        }
    }

    /** hook 带参方法 */
    private void hookMethodWithTypes(ClassLoader cl, String className, String methodName,
                                     Class<?>[] paramTypes, XposedInterface.Hooker hooker) {
        try {
            Class<?> clazz = Class.forName(className, false, cl);
            Method method = clazz.getDeclaredMethod(methodName, paramTypes);
            hook(method)
                    .setExceptionMode(XposedInterface.ExceptionMode.PROTECTIVE)
                    .intercept(hooker);
        } catch (Throwable ignored) {
        }
    }
}
