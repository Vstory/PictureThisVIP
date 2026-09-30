#
# EvalJSHooker: JsbWebView.evaluateJavascript(String, ValueCallback) 安全包裹
# 问题: APP 用 evaluateJavascript 调 window.updateStartupParams(p)，但页面 JS
#       定义前调用 → "updateStartupParams is not a function"
# 解法: 拦截包含 updateStartupParams( 的 JS，改写为安全包裹:
#   (function(p){ if(typeof window.updateStartupParams==='function'){
#      try{window.updateStartupParams(p);}catch(e){}
#    }else{ try{window.startupParams=Object.assign({},window.startupParams||{},p);}catch(e){} }
#   })( PARAMS );
# 其它 JS 原样 proceed
#
.class public Lcom/hook/picturethis/vip/MainHook$EvalJSHooker;
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
# Object intercept(Chain chain) -> void 方法返回 null
.method public intercept(Lio/github/libxposed/api/XposedInterface$Chain;)Ljava/lang/Object;
    .registers 12

    # ===== 1. 读 arg0 =====
    const/4 v0, 0x0

    invoke-interface {p1, v0}, Lio/github/libxposed/api/XposedInterface$Chain;->getArg(I)Ljava/lang/Object;

    move-result-object v0

    # instanceof String 检查
    instance-of v1, v0, Ljava/lang/String;

    if-eqz v1, :skip_rewrite

    move-object v1, v0

    # ===== 2. 包含 "updateStartupParams(" ? =====
    const-string v2, "updateStartupParams("

    invoke-virtual {v1, v2}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v3

    if-eqz v3, :skip_rewrite

    # ===== 3. 提取参数 =====
    # idx = s.indexOf("updateStartupParams(")
    invoke-virtual {v1, v2}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v3

    # after = s.substring(idx + 20)   ["updateStartupParams(" 长度=20]
    const/16 v4, 0x14

    add-int/2addr v3, v4

    invoke-virtual {v1, v3}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v3

    # end = after.lastIndexOf(")")
    const-string v4, ")"

    invoke-virtual {v3, v4}, Ljava/lang/String;->lastIndexOf(Ljava/lang/String;)I

    move-result v5

    # if end < 0 -> skip_rewrite
    if-ltz v5, :skip_rewrite

    # params = after.substring(0, end)
    const/4 v6, 0x0

    invoke-virtual {v3, v6, v5}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v3

    # 去掉结尾分号
    const-string v4, ";"

    invoke-virtual {v3, v4}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v5

    if-eqz v5, :no_semi

    # params = params.substring(0, len-1)
    invoke-virtual {v3}, Ljava/lang/String;->length()I

    move-result v5

    add-int/lit8 v5, v5, -0x1

    const/4 v6, 0x0

    invoke-virtual {v3, v6, v5}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v3

    :no_semi
    # ===== 4. 构造安全包裹 =====
    # wrapped = PREFIX + params + ");"
    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "(function(p){ if(typeof window.updateStartupParams==='function'){try{window.updateStartupParams(p);}catch(e){}}else{try{window.startupParams=Object.assign({},window.startupParams||{},p);}catch(e){}} })( "

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v4, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v5, ");"

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    # ===== 5. 构造新参数数组 {wrapped, arg1} =====
    const/4 v4, 0x2

    new-array v4, v4, [Ljava/lang/Object;

    const/4 v5, 0x0

    aput-object v3, v4, v5

    const/4 v5, 0x1

    invoke-interface {p1, v5}, Lio/github/libxposed/api/XposedInterface$Chain;->getArg(I)Ljava/lang/Object;

    move-result-object v6

    aput-object v6, v4, v5

    # chain.proceed(newArgs)
    invoke-interface {p1, v4}, Lio/github/libxposed/api/XposedInterface$Chain;->proceed([Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    return-object v0

    :skip_rewrite
    # ===== 6. 原样继续 =====
    invoke-interface {p1}, Lio/github/libxposed/api/XposedInterface$Chain;->proceed()Ljava/lang/Object;

    move-result-object v0

    return-object v0
.end method
