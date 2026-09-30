#
# UALoadUrlHooker: WebView.loadUrl(String) 时设置 Chrome UA
# 逻辑: getThisObject() → WebView.getSettings().setUserAgentString(CHROME_UA)
#       → chain.proceed()
# 注意: 必须用 WebSettings.setUserAgentString (公开 API);
#       禁止 WebView.setUserAgentString (隐藏 API, 调用失败)
#
.class public Lcom/hook/picturethis/vip/MainHook$UALoadUrlHooker;
.super Ljava/lang/Object;

# interfaces
.implements Lio/github/libxposed/api/XposedInterface$Hooker;


# direct methods
.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
# Object intercept(Chain chain) -> 设UA后 proceed()
.method public intercept(Lio/github/libxposed/api/XposedInterface$Chain;)Ljava/lang/Object;
    .registers 6

    # ===== 设置 UA (失败不影响 proceed) =====
    :try_start
    invoke-interface {p1}, Lio/github/libxposed/api/XposedInterface$Chain;->getThisObject()Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/webkit/WebView;

    # webView.getSettings() -> WebSettings
    invoke-virtual {v0}, Landroid/webkit/WebView;->getSettings()Landroid/webkit/WebSettings;

    move-result-object v0

    # settings.setUserAgentString(CHROME_UA)
    const-string v1, "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro Build/AP1A.240505.005) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.122 Mobile Safari/537.36"

    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setUserAgentString(Ljava/lang/String;)V
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_ignore

    :catch_ignore
    # ===== 继续原逻辑 =====
    invoke-interface {p1}, Lio/github/libxposed/api/XposedInterface$Chain;->proceed()Ljava/lang/Object;

    move-result-object v0

    return-object v0
.end method
