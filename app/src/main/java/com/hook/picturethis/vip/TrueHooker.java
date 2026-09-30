package com.hook.picturethis.vip;

import io.github.libxposed.api.XposedInterface;

/**
 * 返回 Boolean.TRUE
 * 适用: isXxx() / canXxx() / hasXxx() 等布尔方法
 */
public class TrueHooker implements XposedInterface.Hooker {
    @Override
    public Object intercept(XposedInterface.Chain chain) {
        return Boolean.TRUE;
    }
}
