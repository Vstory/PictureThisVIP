package com.hook.picturethis.vip;

import io.github.libxposed.api.XposedInterface;

/**
 * JsbWebView.evaluateJavascript(String, ValueCallback) 安全包裹
 *
 * 问题: APP 用 evaluateJavascript 调 window.updateStartupParams(p)，但页面 JS
 *       定义前调用 → "updateStartupParams is not a function"
 * 解法: 拦截包含 updateStartupParams( 的 JS，改写为安全包裹:
 *   (function(p){ if(typeof window.updateStartupParams==='function'){
 *      try{window.updateStartupParams(p);}catch(e){}
 *    }else{ try{window.startupParams=Object.assign({},window.startupParams||{},p);}
 *           catch(e){} } })( PARAMS );
 * 其它 JS 原样 proceed
 */
public class EvalJSHooker implements XposedInterface.Hooker {

    private static final String TARGET = "updateStartupParams(";

    private static final String SAFE_WRAPPER_PREFIX =
            "(function(p){ if(typeof window.updateStartupParams==='function'){" +
                    "try{window.updateStartupParams(p);}catch(e){}}" +
                    "else{try{window.startupParams=Object.assign({},window.startupParams||{},p);" +
                    "}catch(e){}} })( ";

    @Override
    public Object intercept(XposedInterface.Chain chain) {
        Object arg0 = chain.getArg(0);

        // instanceof String 检查
        if (!(arg0 instanceof String)) {
            return chain.proceed();
        }

        String js = (String) arg0;

        // 包含 "updateStartupParams(" ?
        if (!js.contains(TARGET)) {
            return chain.proceed();
        }

        // 提取参数
        int idx = js.indexOf(TARGET);
        String after = js.substring(idx + TARGET.length()); // "updateStartupParams(" 长度=20
        int end = after.lastIndexOf(")");
        if (end < 0) {
            return chain.proceed();
        }
        String params = after.substring(0, end);
        // 去掉结尾分号
        if (params.endsWith(";")) {
            params = params.substring(0, params.length() - 1);
        }

        // 构造安全包裹
        String wrapped = SAFE_WRAPPER_PREFIX + params + ");";

        // 构造新参数数组 {wrapped, arg1}
        Object arg1 = chain.getArg(1);
        Object[] newArgs = new Object[]{wrapped, arg1};
        return chain.proceed(newArgs);
    }
}
