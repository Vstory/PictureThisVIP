package com.hook.picturethis.vip;

import android.webkit.WebSettings;
import android.webkit.WebView;
import io.github.libxposed.api.XposedInterface;

/**
 * WebView.loadUrl(String) 时设置 Chrome UA
 * 逻辑: getThisObject() → WebView.getSettings().setUserAgentString(CHROME_UA) → chain.proceed()
 * 注意: 必须用 WebSettings.setUserAgentString (公开 API)
 */
public class UALoadUrlHooker implements XposedInterface.Hooker {

    private static final String CHROME_UA =
            "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro Build/AP1A.240505.005) "
                    + "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.122"
                    + " Mobile Safari/537.36";

    @Override
    public Object intercept(XposedInterface.Chain chain) {
        try {
            Object thiz = chain.getThisObject();
            WebView webView = (WebView) thiz;
            WebSettings settings = webView.getSettings();
            settings.setUserAgentString(CHROME_UA);
        } catch (Throwable ignored) {
        }
        return chain.proceed();
    }
}
