package com.hook.picturethis.vip;

import android.net.Uri;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import io.github.libxposed.api.XposedInterface;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * WebViewClient.shouldInterceptRequest 代拉
 * 目标: WebViewClientProxy.shouldInterceptRequest(WebView, WebResourceRequest)
 * 逻辑: 读 arg1(WebResourceRequest) → url → 含 "cms-cache.picture" 则用
 *       HttpURLConnection 代拉 → 读 byte[] → ByteArrayInputStream → 返回
 *       WebResourceResponse(mimeType, encoding, data) [默认200 OK]
 *       其它请求 → chain.proceed() 走原逻辑
 */
public class WebViewInterceptor implements XposedInterface.Hooker {

    private static final String TARGET_DOMAIN = "cms-cache.picture";

    private static final String CHROME_UA =
            "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro Build/AP1A.240505.005) "
                    + "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.122"
                    + " Mobile Safari/537.36";

    @Override
    public Object intercept(XposedInterface.Chain chain) {
        // 1. 读 arg1 → WebResourceRequest → url
        Object arg1 = chain.getArg(1);
        WebResourceRequest request = (WebResourceRequest) arg1;
        Uri uri = request.getUrl();
        String url = uri.toString();

        // 2. 判断域名
        if (!url.contains(TARGET_DOMAIN)) {
            return chain.proceed();
        }

        // 3. 代拉
        try {
            URL u = new URL(url);
            HttpURLConnection conn = (HttpURLConnection) u.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("User-Agent", CHROME_UA);
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(15000);
            conn.connect();

            int code = conn.getResponseCode();
            if (code != 200) {
                conn.disconnect();
                return chain.proceed();
            }

            InputStream is = conn.getInputStream();
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buf = new byte[4096];
            int n;
            while ((n = is.read(buf)) != -1) {
                baos.write(buf, 0, n);
            }
            is.close();

            byte[] data = baos.toByteArray();
            ByteArrayInputStream bais = new ByteArrayInputStream(data);
            String contentType = conn.getContentType();

            // 3参数版 WebResourceResponse 默认200 OK
            WebResourceResponse response = new WebResourceResponse(
                    contentType, "utf-8", bais);

            conn.disconnect();
            return response;
        } catch (Throwable ignored) {
        }

        // 4. 代拉异常 → 走原逻辑
        return chain.proceed();
    }
}
