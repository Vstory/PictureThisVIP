package com.hook.picturethis.vip;

import io.github.libxposed.api.XposedInterface;

/**
 * 返回 Boolean.FALSE
 * 适用: isTrial() / isFakeVip() 等需要返回 false 的方法
 */
public class FalseHooker implements XposedInterface.Hooker {
    @Override
    public Object intercept(XposedInterface.Chain chain) {
        return Boolean.FALSE;
    }
}
