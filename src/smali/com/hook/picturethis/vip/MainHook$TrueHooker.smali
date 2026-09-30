#
# Hooker 模板 1: 返回 Boolean.TRUE
# 适用: isXxx() / canXxx() / hasXxx() 等布尔方法
# 要点: intercept() 返回值 = 方法最终返回值（无 setResult）
#
.class public Lcom/hook/picturethis/vip/MainHook$TrueHooker;
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
# Object intercept(Chain chain) -> Boolean.TRUE
.method public intercept(Lio/github/libxposed/api/XposedInterface$Chain;)Ljava/lang/Object;
    .registers 2

    const/4 v0, 0x1

    invoke-static {v0}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;

    move-result-object v0

    return-object v0
.end method
