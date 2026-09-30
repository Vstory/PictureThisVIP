#
# Hooker: 返回 Boolean.FALSE
# 适用: isTrial() / isFakeVip() 等需要返回 false 的方法
#
.class public Lcom/hook/picturethis/vip/MainHook$FalseHooker;
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
# Object intercept(Chain chain) -> Boolean.FALSE
.method public intercept(Lio/github/libxposed/api/XposedInterface$Chain;)Ljava/lang/Object;
    .registers 2

    const/4 v0, 0x0

    invoke-static {v0}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object v0

    return-object v0
.end method
