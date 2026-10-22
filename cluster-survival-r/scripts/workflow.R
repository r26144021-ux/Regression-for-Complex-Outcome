# 使用方式：source("cluster-survival-r/scripts/workflow.R", encoding="UTF-8")
need_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly=TRUE))
    stop(sprintf('缺少套件 %s；請執行 install.packages("%s", repos="https://cloud.r-project.org")',pkg,pkg))
}
read_data <- function(x, sheet=NULL, encoding="UTF-8", sep=",") {
  if (is.data.frame(x)) return(x)
  ext <- tolower(tools::file_ext(x))
  if (ext == "csv") return(read.table(x,header=TRUE,sep=sep,fileEncoding=encoding,
                                      check.names=FALSE,stringsAsFactors=FALSE))
  if (ext %in% c("xls","xlsx")) {
    need_package("readxl")
    if (is.null(sheet)) stop(paste("請先選工作表：",paste(readxl::excel_sheets(x),collapse=", ")))
    return(as.data.frame(readxl::read_excel(x,sheet=sheet)))
  }
  stop("請提供 data.frame、CSV 或 XLS/XLSX")
}
audit_data <- function(d) {
  stopifnot(is.data.frame(d))
  cat("資料列數：",nrow(d),"；欄數：",ncol(d),"\n")
  data.frame(欄位=names(d),型別=vapply(d,function(z) paste(class(z),collapse="/"),""),
    缺失數=vapply(d,function(z) sum(is.na(z)),0L),
    範例=vapply(d,function(z) paste(head(unique(z),5),collapse=" | "),""),check.names=FALSE)
}
check_columns <- function(d,cols) {
  if (anyDuplicated(names(d))) stop("欄名重複，請先修正")
  if (!all(cols %in% names(d))) stop("缺少分析欄位")
  if (anyNA(d[,cols,drop=FALSE])) stop("分析欄位有缺失；請先確認處理方式並記錄排除列數")
  for (z in d[,cols,drop=FALSE]) if (is.numeric(z) && any(!is.finite(z))) stop("分析欄位有非有限數值")
}
wald_table <- function(beta,V,exponentiate=FALSE) {
  se <- sqrt(diag(V)); z <- beta/se
  ans <- data.frame(term=names(beta),estimate=unname(beta),SE=unname(se),
                    lower=unname(beta-1.96*se),upper=unname(beta+1.96*se),
                    p=unname(2*pnorm(-abs(z))))
  if(exponentiate) ans[,c("estimate","lower","upper")] <- exp(ans[,c("estimate","lower","upper")])
  ans
}
fit_cox <- function(d,formula,time,event,ties="efron") {
  need_package("survival")
  check_columns(d,unique(c(all.vars(formula),time,event)))
  if (!is.numeric(d[[event]]) || !all(d[[event]] %in% c(0,1))) stop("event 必須為數值 0=設限、1=事件；其他編碼請先確認意義再轉換")
  if (!is.numeric(d[[time]]) || any(d[[time]]<=0)) stop("基本右設限範例需正數時間；零時間需先檢查記錄規則")
  if (!any(d[[event]]==1)) stop("沒有事件，無法配適 Cox")
  m <- survival::coxph(formula,data=d,ties=ties,x=TRUE,y=TRUE,na.action=na.fail)
  list(model=m,table=wald_table(coef(m),vcov(m),TRUE),ph=survival::cox.zph(m),
       n=nrow(d),events=sum(d[[event]]))
}
fit_mixed <- function(d,formula,family=NULL,REML=TRUE) {
  need_package("lme4"); check_columns(d,all.vars(formula))
  if(!length(lme4::findbars(formula)))
    stop("混合效應模型需有已確認的隨機效果；不自動改跑一般線性／logistic 迴歸。請先釐清群集角色與模型是否適用")
  m <- if(is.null(family)) lme4::lmer(formula,data=d,REML=REML,na.action=na.fail) else
    lme4::glmer(formula,data=d,family=family,na.action=na.fail)
  if(!inherits(m,"merMod")) stop("模型類型與已選混合效應模型不符；停止解釋")
  tab <- wald_table(lme4::fixef(m),as.matrix(vcov(m)),!is.null(family) && family$link %in% c("log","logit"))
  # LMM 不把近似 z p 值當成預設推論；保留 Wald CI。
  if(is.null(family)) tab$p <- NULL
  list(model=m,table=tab,singular=lme4::isSingular(m),
       convergence=m@optinfo$conv,variance=as.data.frame(lme4::VarCorr(m)))
}
fit_nlmm <- function(d,model,fixed,random,groups,start,parameters,method="ML") {
  need_package("nlme")
  # 參數符號不應被當作資料欄位；由已確認的 parameters 明確區分。
  cols <- setdiff(unique(c(all.vars(model),all.vars(fixed),all.vars(random),all.vars(groups))),parameters)
  check_columns(d,cols)
  if(!is.numeric(start) || is.null(names(start)) || any(!is.finite(start)))
    stop("請提供已確認且具名的有限數值起始值")
  m <- nlme::nlme(model=model,data=d,fixed=fixed,random=random,groups=groups,
                  start=start,method=method,na.action=na.fail)
  list(model=m,table=summary(m)$tTable,variance=nlme::VarCorr(m),
       intervals=tryCatch(nlme::intervals(m,which="fixed"),error=function(e) conditionMessage(e)))
}
fit_gee <- function(d,formula,id,waves,family,corstr="exchangeable") {
  need_package("geepack"); check_columns(d,unique(c(all.vars(formula),id,waves)))
  if (!is.numeric(d[[waves]])) stop("waves 請明確轉為具有訪視意義的數值")
  if (anyDuplicated(d[,c(id,waves)])) stop("存在重複 id-waves，請先釐清同次訪視的重複列")
  if (length(unique(d[[id]]))<2) stop("獨立群不足")
  K <- length(unique(d[[id]]))
  if (K<40) warning("獨立群數偏少：請評估小樣本修正；30 或 40 都不是安全保證門檻。此函數未實作 KC／MD／FG")
  d <- d[order(d[[id]],d[[waves]]),,drop=FALSE]
  # 以區域欄位避免 geeglm 的非標準求值抓不到外部欄名。
  if(any(c(".skill_id",".skill_wave") %in% names(d))) stop("保留欄名衝突")
  d$.skill_id <- d[[id]]; d$.skill_wave <- d[[waves]]
  m <- geepack::geeglm(formula,data=d,id=.skill_id,waves=.skill_wave,
                       family=family,corstr=corstr,std.err="san.se",na.action=na.fail)
  if(m$geese$error!=0) warning("GEE 未正常收斂；請勿直接解釋")
  tab <- wald_table(coef(m),m$geese$vbeta,family$link %in% c("log","logit"))
  # 少群仍可估計；避免把未修正的大樣本 CI／p 當成可靠正式推論。
  # 原始 model 內仍有套件預設輸出，解釋時應遵循 inference_note。
  if(K<30) tab[,c("lower","upper","p")] <- NA_real_
  list(model=m,table=tab,
       QIC=geepack::QIC(m),clusters=K,data=d,
       small_sample_corrected=FALSE,
       inference_note=if(K<30) "僅探索性估計；未修正 CI／p 已隱藏。正式推論需另選並驗證小樣本修正" else
         "未做小樣本修正的大樣本 Wald 推論；需依群數與設計評估適用性")
}
