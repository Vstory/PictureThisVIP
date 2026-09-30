#
# WebViewInterceptor: shouldInterceptRequest 代拉
# 目标: WebViewClient.shouldInterceptRequest(WebView, WebResourceRequest)
# 逻辑: 读 arg1(WebResourceRequest) → url → 含 "cms-cache.picture" 则用
#       HttpURLConnection 代拉 → 读 byte[] → ByteArrayInputStream → 返回
#       WebResourceResponse(3参数版: mimeType, encoding, data) [默认200 OK]
#       其它请求 → chain.proceed() 走原逻辑
# 已验证: Frida v15 全资源 HTTP 200 (HTML/CSS/JS/图片)
#
.class public Lcom/hook/picturethis/vip/MainHook$WebViewInterceptor;
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
# Object intercept(Chain chain) -> WebResourceResponse | chain.proceed()
.method public intercept(Lio/github/libxposed/api/XposedInterface$Chain;)Ljava/lang/Object;
    .registers 15

    # ===== 1. 读 arg1 → WebResourceRequest → url =====
    const/4 v0, 0x1

    invoke-interface {p1, v0}, Lio/github/libxposed/api/XposedInterface$Chain;->getArg(I)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/webkit/WebResourceRequest;

    move-object v1, v0

    # request.getUrl() -> Uri
    invoke-interface {v1}, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;

    move-result-object v2

    # uri.toString() -> String
    invoke-virtual {v2}, Landroid/net/Uri;->toString()Ljava/lang/String;

    move-result-object v3

    # ===== 2. 判断域名 =====
    const-string v4, "cms-cache.picture"

    invoke-virtual {v3, v4}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v4

    if-nez v4, :skip_fetch

    # ===== 3. 代拉 =====
    :try_start
    # URL u = new URL(url)
    new-instance v5, Ljava/net/URL;

    invoke-direct {v5, v3}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    # conn = (HttpURLConnection) u.openConnection()
    invoke-virtual {v5}, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;

    move-result-object v6

    check-cast v6, Ljava/net/HttpURLConnection;

    # conn.setRequestMethod("GET")
    const-string v7, "GET"

    invoke-virtual {v6, v7}, Ljava/net/HttpURLConnection;->setRequestMethod(Ljava/lang/String;)V

    # conn.setRequestProperty("User-Agent", CHROME_UA)
    const-string v7, "User-Agent"

    const-string v8, "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro Build/AP1A.240505.005) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.122 Mobile Safari/537.36"

    invoke-virtual {v6, v7, v8}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    # conn.setConnectTimeout(10000)
    const/16 v7, 0x2710

    invoke-virtual {v6, v7}, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V

    # conn.setReadTimeout(15000)
    const/16 v7, 0x3a98

    invoke-virtual {v6, v7}, Ljava/net/HttpURLConnection;->setReadTimeout(I)V

    # conn.connect()
    invoke-virtual {v6}, Ljava/net/HttpURLConnection;->connect()V

    # code = conn.getResponseCode()
    invoke-virtual {v6}, Ljava/net/HttpURLConnection;->getResponseCode()I

    move-result v7

    # if code != 200 -> skip_response (fallthrough 到 proceed)
    const/16 v8, 0xc8

    if-ne v7, v8, :skip_response

    # InputStream is = conn.getInputStream()
    invoke-virtual {v6}, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;

    move-result-object v7

    # ByteArrayOutputStream baos = new ByteArrayOutputStream()
    new-instance v8, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v8}, Ljava/io/ByteArrayOutputStream;-><init>()V

    # byte[] buf = new byte[4096]
    const/16 v9, 0x1000

    new-array v9, v9, [B

    :read_loop
    # n = is.read(buf)
    invoke-virtual {v7, v9}, Ljava/io/InputStream;->read([B)I

    move-result v10

    # if n < 0 -> done
    if-ltz v10, :read_done

    # baos.write(buf, 0, n)
    const/4 v11, 0x0

    invoke-virtual {v8, v9, v11, v10}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    goto :read_loop

    :read_done
    # is.close()
    invoke-virtual {v7}, Ljava/io/InputStream;->close()V

    # byte[] data = baos.toByteArray()
    invoke-virtual {v8}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object v7

    # ByteArrayInputStream bais = new ByteArrayInputStream(data)
    new-instance v8, Ljava/io/ByteArrayInputStream;

    invoke-direct {v8, v7}, Ljava/io/ByteArrayInputStream;-><init>([B)V

    # String ct = conn.getContentType()
    invoke-virtual {v6}, Ljava/net/HttpURLConnection;->getContentType()Ljava/lang/String;

    move-result-object v9

    # return new WebResourceResponse(ct, "utf-8", bais)  — 3参数版默认200 OK
    new-instance v10, Landroid/webkit/WebResourceResponse;

    const-string v11, "utf-8"

    invoke-direct {v10, v9, v11, v8}, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String;Ljava/lang/String;Ljava/io/InputStream;)V

    # conn.disconnect()
    invoke-virtual {v6}, Ljava/net/HttpURLConnection;->disconnect()V

    return-object v10

    :skip_response
    # code != 200 -> disconnect -> fallthrough
    invoke-virtual {v6}, Ljava/net/HttpURLConnection;->disconnect()V
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_fetch

    :catch_fetch
    # 代拉异常 -> fallthrough 到 proceed()

    :skip_fetch
    # ===== 4. 非目标/失败 → 原逻辑 =====
    invoke-interface {p1}, Lio/github/libxposed/api/XposedInterface$Chain;->proceed()Ljava/lang/Object;

    move-result-object v0

    return-object v0
.end method
