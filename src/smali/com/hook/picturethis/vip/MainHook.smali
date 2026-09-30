#
# ============================================================
# PictureThis VIP Unlock 模块 (API 102) — v2
# 目标: cn.danatech.xingseus (PictureThis)
# 功能:
#   v1: VIP模拟 + 权限闸门绕过
#   v2: + WebView 代拉 (shouldInterceptRequest 绕 CloudFront TLS 拦截)
#       + UA 伪装 (loadUrl 时 setUserAgentString)
#       + updateStartupParams 安全包裹 (evaluateJavascript 改写)
# ============================================================
# 已验证 hook 方案 (Aide Frida v15):
#   1. CheckPointManager.isPremiumFeatureEligible → true
#   2. VipInfo.isVip/isVipInHistory/isPaidInHistory → true
#   3. VipInfo.isTrial → false
#   4. GLMPAccount.isVip → true
#   5. GLMPAccount.isTrial/isFakeVip → false
#   6. AppContext.isVip → true
#   7. WebViewClientProxy.shouldInterceptRequest → 代拉 cms-cache
#   8. WebView.loadUrl → 设 Chrome UA
#   9. JsbWebView.evaluateJavascript → 安全包裹 updateStartupParams
# ============================================================
#
.class public Lcom/hook/picturethis/vip/MainHook;
.super Lio/github/libxposed/api/XposedModule;

.field private mAppClassLoader:Ljava/lang/ClassLoader;


.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Lio/github/libxposed/api/XposedModule;-><init>()V

    return-void
.end method

# 通用 hook 辅助（无参方法版）
.method private hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V
    .registers 7

    :try_start
    const/4 v0, 0x0

    invoke-static {p2, v0, p1}, Ljava/lang/Class;->forName(Ljava/lang/String;ZLjava/lang/ClassLoader;)Ljava/lang/Class;

    move-result-object v0

    const/4 v1, 0x0

    new-array v1, v1, [Ljava/lang/Class;

    invoke-virtual {v0, p3, v1}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    invoke-virtual {p0, v0}, Lio/github/libxposed/api/XposedInterfaceWrapper;->hook(Ljava/lang/reflect/Executable;)Lio/github/libxposed/api/XposedInterface$HookBuilder;

    move-result-object v0

    sget-object v1, Lio/github/libxposed/api/XposedInterface$ExceptionMode;->PROTECTIVE:Lio/github/libxposed/api/XposedInterface$ExceptionMode;

    invoke-interface {v0, v1}, Lio/github/libxposed/api/XposedInterface$HookBuilder;->setExceptionMode(Lio/github/libxposed/api/XposedInterface$ExceptionMode;)Lio/github/libxposed/api/XposedInterface$HookBuilder;

    move-result-object v0

    invoke-interface {v0, p4}, Lio/github/libxposed/api/XposedInterface$HookBuilder;->intercept(Lio/github/libxposed/api/XposedInterface$Hooker;)Lio/github/libxposed/api/XposedInterface$HookHandle;
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_ignore

    :catch_ignore
    return-void
.end method

# 带参方法: 取 Method (参数类型数组由调用方构造)
# 4 参数 + this = 5 寄存器, 普通 invoke-direct 上限内
.method private getDeclaredMethodWithTypes(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;
    .registers 7

    :try_start
    const/4 v0, 0x0

    invoke-static {p2, v0, p1}, Ljava/lang/Class;->forName(Ljava/lang/String;ZLjava/lang/ClassLoader;)Ljava/lang/Class;

    move-result-object v0

    invoke-virtual {v0, p3, p4}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    return-object v0
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_ignore

    :catch_ignore
    const/4 v0, 0x0

    return-object v0
.end method

# 已取到 Method 直接 hook（配合 getDeclaredMethodWithTypes）
.method private hookMethodRef(Ljava/lang/reflect/Method;Lio/github/libxposed/api/XposedInterface$Hooker;)V
    .registers 5

    :try_start
    invoke-virtual {p0, p1}, Lio/github/libxposed/api/XposedInterfaceWrapper;->hook(Ljava/lang/reflect/Executable;)Lio/github/libxposed/api/XposedInterface$HookBuilder;

    move-result-object v0

    sget-object v1, Lio/github/libxposed/api/XposedInterface$ExceptionMode;->PROTECTIVE:Lio/github/libxposed/api/XposedInterface$ExceptionMode;

    invoke-interface {v0, v1}, Lio/github/libxposed/api/XposedInterface$HookBuilder;->setExceptionMode(Lio/github/libxposed/api/XposedInterface$ExceptionMode;)Lio/github/libxposed/api/XposedInterface$HookBuilder;

    move-result-object v0

    invoke-interface {v0, p2}, Lio/github/libxposed/api/XposedInterface$HookBuilder;->intercept(Lio/github/libxposed/api/XposedInterface$Hooker;)Lio/github/libxposed/api/XposedInterface$HookHandle;
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_ignore

    :catch_ignore
    return-void
.end method


# 安装全部 hooks
# 寄存器布局 (.registers 12, 2参数): p0=v10(this), p1=v11(classLoader)
#   v0=TrueHooker v1=FalseHooker v2=WebViewInterceptor v3=UALoadUrlHooker v4=EvalJSHooker
#   v5=className v6=methodName v7=paramTypes v8=Method/临时 v9=临时
.method private installHooks(Ljava/lang/ClassLoader;)V
    .registers 12

    # 创建 Hooker 实例
    new-instance v0, Lcom/hook/picturethis/vip/MainHook$TrueHooker;
    invoke-direct {v0}, Lcom/hook/picturethis/vip/MainHook$TrueHooker;-><init>()V

    new-instance v1, Lcom/hook/picturethis/vip/MainHook$FalseHooker;
    invoke-direct {v1}, Lcom/hook/picturethis/vip/MainHook$FalseHooker;-><init>()V

    new-instance v2, Lcom/hook/picturethis/vip/MainHook$WebViewInterceptor;
    invoke-direct {v2}, Lcom/hook/picturethis/vip/MainHook$WebViewInterceptor;-><init>()V

    new-instance v3, Lcom/hook/picturethis/vip/MainHook$UALoadUrlHooker;
    invoke-direct {v3}, Lcom/hook/picturethis/vip/MainHook$UALoadUrlHooker;-><init>()V

    new-instance v4, Lcom/hook/picturethis/vip/MainHook$EvalJSHooker;
    invoke-direct {v4}, Lcom/hook/picturethis/vip/MainHook$EvalJSHooker;-><init>()V

    # ==============================================
    # 1. CheckPointManager.isPremiumFeatureEligible → true
    # ==============================================
    const-string v5, "com.glority.android.common.manager.CheckPointManager"
    const-string v6, "isPremiumFeatureEligible"
    invoke-direct {p0, p1, v5, v6, v0}, Lcom/hook/picturethis/vip/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    # ==============================================
    # 2. VipInfo.isVip → true / isTrial → false / isVipInHistory → true / isPaidInHistory → true
    # ==============================================
    const-string v5, "com.glority.component.generatedAPI.kotlinAPI.vip.VipInfo"
    const-string v6, "isVip"
    invoke-direct {p0, p1, v5, v6, v0}, Lcom/hook/picturethis/vip/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    const-string v6, "isTrial"
    invoke-direct {p0, p1, v5, v6, v1}, Lcom/hook/picturethis/vip/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    const-string v6, "isVipInHistory"
    invoke-direct {p0, p1, v5, v6, v0}, Lcom/hook/picturethis/vip/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    const-string v6, "isPaidInHistory"
    invoke-direct {p0, p1, v5, v6, v0}, Lcom/hook/picturethis/vip/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    # ==============================================
    # 3. GLMPAccount.isVip → true / isTrial → false / isFakeVip → false
    # ==============================================
    const-string v5, "com.glority.android.glmp.GLMPAccount"
    const-string v6, "isVip"
    invoke-direct {p0, p1, v5, v6, v0}, Lcom/hook/picturethis/vip/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    const-string v6, "isTrial"
    invoke-direct {p0, p1, v5, v6, v1}, Lcom/hook/picturethis/vip/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    const-string v6, "isFakeVip"
    invoke-direct {p0, p1, v5, v6, v1}, Lcom/hook/picturethis/vip/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    # ==============================================
    # 4. AppContext.isVip → true
    # ==============================================
    const-string v5, "com.glority.android.core.app.AppContext"
    const-string v6, "isVip"
    invoke-direct {p0, p1, v5, v6, v0}, Lcom/hook/picturethis/vip/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    # ==============================================
    # 5. WebViewClientProxy.shouldInterceptRequest(WebView, WebResourceRequest)
    #    → 代拉 cms-cache 资源 (WebViewInterceptor)
    # ==============================================
    const-string v5, "com.glority.base.widget.webview.WebViewClientProxy"
    const-string v6, "shouldInterceptRequest"

    const/4 v9, 0x2
    new-array v7, v9, [Ljava/lang/Class;
    const-class v9, Landroid/webkit/WebView;
    const/4 v8, 0x0
    aput-object v9, v7, v8
    const-class v9, Landroid/webkit/WebResourceRequest;
    const/4 v8, 0x1
    aput-object v9, v7, v8

    invoke-direct {p0, p1, v5, v6, v7}, Lcom/hook/picturethis/vip/MainHook;->getDeclaredMethodWithTypes(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v8
    invoke-direct {p0, v8, v2}, Lcom/hook/picturethis/vip/MainHook;->hookMethodRef(Ljava/lang/reflect/Method;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    # ==============================================
    # 6. WebView.loadUrl(String) → 设 Chrome UA (UALoadUrlHooker)
    # ==============================================
    const-string v5, "android.webkit.WebView"
    const-string v6, "loadUrl"

    const/4 v9, 0x1
    new-array v7, v9, [Ljava/lang/Class;
    const-class v9, Ljava/lang/String;
    const/4 v8, 0x0
    aput-object v9, v7, v8

    invoke-direct {p0, p1, v5, v6, v7}, Lcom/hook/picturethis/vip/MainHook;->getDeclaredMethodWithTypes(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v8
    invoke-direct {p0, v8, v3}, Lcom/hook/picturethis/vip/MainHook;->hookMethodRef(Ljava/lang/reflect/Method;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    # ==============================================
    # 7. JsbWebView.evaluateJavascript(String, ValueCallback)
    #    → updateStartupParams 安全包裹 (EvalJSHooker)
    # ==============================================
    const-string v5, "com.example.glwebview.JsbWebView"
    const-string v6, "evaluateJavascript"

    const/4 v9, 0x2
    new-array v7, v9, [Ljava/lang/Class;
    const-class v9, Ljava/lang/String;
    const/4 v8, 0x0
    aput-object v9, v7, v8
    const-class v9, Landroid/webkit/ValueCallback;
    const/4 v8, 0x1
    aput-object v9, v7, v8

    invoke-direct {p0, p1, v5, v6, v7}, Lcom/hook/picturethis/vip/MainHook;->getDeclaredMethodWithTypes(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v8
    invoke-direct {p0, v8, v4}, Lcom/hook/picturethis/vip/MainHook;->hookMethodRef(Ljava/lang/reflect/Method;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    return-void
.end method


# onModuleLoaded
.method public onModuleLoaded(Lio/github/libxposed/api/XposedModuleInterface$ModuleLoadedParam;)V
    .registers 5

    const/4 v0, 0x4
    const-string v1, "PictureThisVIP"
    const-string v2, "api102 module loaded"
    invoke-virtual {p0, v0, v1, v2}, Lio/github/libxposed/api/XposedInterfaceWrapper;->log(ILjava/lang/String;Ljava/lang/String;)V

    return-void
.end method

# onPackageReady
.method public onPackageReady(Lio/github/libxposed/api/XposedModuleInterface$PackageReadyParam;)V
    .registers 6

    invoke-interface {p1}, Lio/github/libxposed/api/XposedModuleInterface$PackageReadyParam;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object v0

    iput-object v0, p0, Lcom/hook/picturethis/vip/MainHook;->mAppClassLoader:Ljava/lang/ClassLoader;

    invoke-direct {p0, v0}, Lcom/hook/picturethis/vip/MainHook;->installHooks(Ljava/lang/ClassLoader;)V

    const/4 v1, 0x4
    const-string v2, "PictureThisVIP"
    const-string v3, "hooks installed"
    invoke-virtual {p0, v1, v2, v3}, Lio/github/libxposed/api/XposedInterfaceWrapper;->log(ILjava/lang/String;Ljava/lang/String;)V

    return-void
.end method

# 允许热重载
.method public onHotReloading(Lio/github/libxposed/api/XposedModuleInterface$HotReloadingParam;)Z
    .registers 3

    const/4 v0, 0x1
    return v0
.end method

# 热重载处理
.method public onHotReloaded(Lio/github/libxposed/api/XposedModuleInterface$HotReloadedParam;)V
    .registers 8

    const/4 v0, 0x0

    invoke-interface {p1}, Lio/github/libxposed/api/XposedModuleInterface$HotReloadedParam;->getOldHookHandles()Ljava/util/List;

    move-result-object v1

    invoke-interface {v1}, Ljava/util/List;->isEmpty()Z

    move-result v2

    if-nez v2, :try_handle

    const/4 v2, 0x0

    invoke-interface {v1, v2}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Lio/github/libxposed/api/XposedInterface$HookHandle;

    invoke-interface {v1}, Lio/github/libxposed/api/XposedInterface$HookHandle;->getExecutable()Ljava/lang/reflect/Executable;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/reflect/Executable;->getDeclaringClass()Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Class;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object v0

    :try_handle
    invoke-interface {p1}, Lio/github/libxposed/api/XposedModuleInterface$HotReloadedParam;->getOldHookHandles()Ljava/util/List;

    move-result-object v1

    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :loop_unhook
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :done_unhook

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/libxposed/api/XposedInterface$HookHandle;

    invoke-interface {v2}, Lio/github/libxposed/api/XposedInterface$HookHandle;->unhook()V

    goto :loop_unhook

    :done_unhook
    if-nez v0, :have_cl

    iget-object v0, p0, Lcom/hook/picturethis/vip/MainHook;->mAppClassLoader:Ljava/lang/ClassLoader;

    :have_cl
    if-nez v0, :install

    return-void

    :install
    invoke-direct {p0, v0}, Lcom/hook/picturethis/vip/MainHook;->installHooks(Ljava/lang/ClassLoader;)V

    const/4 v1, 0x4
    const-string v2, "PictureThisVIP"
    const-string v3, "hot reloaded, hooks reinstalled"
    invoke-virtual {p0, v1, v2, v3}, Lio/github/libxposed/api/XposedInterfaceWrapper;->log(ILjava/lang/String;Ljava/lang/String;)V

    return-void
.end method
