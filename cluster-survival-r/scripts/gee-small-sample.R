# 補充路徑：MD 修正的係數別推論；非所有 GEE 設計的通用解法。
# 先 source scripts/workflow.R；df 與 df_reason 須按研究設計明確指定。
fit_gee_md <- function(d, formula, id, waves, family="gaussian", df, df_reason) {
  need_package("gee"); need_package("geesmv")
  if(!family %in% c("gaussian","binomial","poisson")) stop("此路徑只支援 canonical Gaussian／binomial／Poisson")
  if(missing(df) || missing(df_reason) || !is.numeric(df) || length(df)!=1 || !is.finite(df) || df<=0 ||
     !is.character(df_reason) || length(df_reason)!=1 || !nzchar(df_reason)) stop("請明確指定正數自由度 df 與設計理由 df_reason")
  check_columns(d,unique(c(all.vars(formula),id,waves)))
  if(anyDuplicated(d[,c(id,waves)])) stop("重複 id-time")
  d <- d[order(d[[id]],d[[waves]]),,drop=FALSE]
  # geesmv 內部固定使用 id 欄，先在局部副本明確映射，避免與其他 id 欄衝突。
  d$id <- as.integer(factor(d[[id]],levels=unique(d[[id]])))
  K <- length(unique(d$id))
  if(K<3 || any(table(d$id)<2)) stop("此受限路徑需至少 3 個獨立群且每群至少 2 列")
  mf <- model.frame(formula,d,na.action=na.fail); y <- model.response(mf)
  if(!is.numeric(y) || is.matrix(y)) stop("僅支援單欄數值結果；不支援彙總二項或因子結果")
  if(length(attr(terms(formula),"offset"))) stop("此受限路徑不支援 offset")
  if(family=="binomial" && !all(y %in% c(0,1))) stop("binomial 結果需明確 0／1")
  if(family=="poisson" && any(y<0 | y!=floor(y))) stop("Poisson 需非負整數")
  X <- model.matrix(formula,mf)
  if(qr(X)$rank<ncol(X) || K<=ncol(X)) stop("共線或獨立群相對參數不足")
  # 本版本限定 independence；不將 geepack 的估計與另一套件的變異數拼接。
  m <- gee::gee(formula,data=d,id=d$id,family=family,corstr="independence")
  if(!is.null(m$error) && any(m$error!=0)) stop("gee 未正常收斂")
  md <- geesmv::GEE.var.md(formula,id="id",family=family,data=d,corstr="independence")
  beta <- coef(m); vars <- as.numeric(md$cov.beta)
  if(length(vars)!=length(beta) || any(!is.finite(c(beta,vars))) || any(vars<=0)) stop("MD 變異數或估計無效")
  se <- sqrt(vars);crit <- qt(.975,df)
  tab <- data.frame(term=names(beta),estimate=unname(beta),SE=se,
                    lower=unname(beta-crit*se),upper=unname(beta+crit*se),
                    df=df,p=unname(2*pt(-abs(beta/se),df)))
  if(family %in% c("binomial","poisson")) tab[,c("estimate","lower","upper")] <- exp(tab[,c("estimate","lower","upper")])
  list(model=m,table=tab,clusters=K,correction="Mancl-DeRouen (MD)",
       reference="coefficient-wise t",df_reason=df_reason,
       corstr="independence",small_sample_corrected=TRUE,
       limitations="仍需設計適用性審查；非全協方差輸出，不提供多參數聯合檢定；不是極少群的可靠性保證")
}
