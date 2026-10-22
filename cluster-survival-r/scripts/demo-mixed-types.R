# 在包含 cluster-survival-r 的資料夾執行。
# 此檔示範已明確指定研究目標與模型設定的情況；不替代真實資料的前置對話。
args <- commandArgs(trailingOnly=TRUE)
root <- if(length(args)) args[1] else "cluster-survival-r"
out <- if(length(args)>1) args[2] else "demo-results"
dir.create(out,recursive=TRUE,showWarnings=FALSE)
source(file.path(root,"scripts","workflow.R"),encoding="UTF-8")

# GLMM：cbpp 各 herd 重複觀測二元事件的彙總計數。
need_package("lme4")
d <- lme4::cbpp
g <- fit_mixed(d,cbind(incidence,size-incidence)~period+(1|herd),family=binomial())
write.csv(g$table,file.path(out,"glmm.csv"),row.names=FALSE)

# NLMM：Loblolly 樹高的漸近生長曲線，Asym 因樹而異。
# SSasymp = Asym + (R0-Asym)*exp(-exp(lrc)*age)。起始值來自官方示範。
need_package("nlme")
t <- as.data.frame(datasets::Loblolly)
n <- fit_nlmm(t,height~SSasymp(age,Asym,R0,lrc),Asym+R0+lrc~1,Asym~1,~Seed,
              c(Asym=103,R0=-8.5,lrc=-3.3),parameters=c("Asym","R0","lrc"))
# 另一組合理起始值，檢查是否到達相同估計。
n2 <- fit_nlmm(t,height~SSasymp(age,Asym,R0,lrc),Asym+R0+lrc~1,Asym~1,~Seed,
               c(Asym=100,R0=-7,lrc=-3),parameters=c("Asym","R0","lrc"))
stopifnot(max(abs(nlme::fixef(n$model)-nlme::fixef(n2$model)))<0.01)
write.csv(n$table,file.path(out,"nlmm.csv"))
png(file.path(out,"nlmm-diagnostics.png"),width=1200,height=600,res=120)
par(mfrow=c(1,2))
plot(fitted(n$model),resid(n$model,type="normalized"),xlab="Fitted",ylab="Normalized residuals");abline(h=0,lty=2)
qqnorm(resid(n$model,type="normalized"));qqline(resid(n$model,type="normalized"));dev.off()
capture.output({cat("GLMM\n");print(g$table);print(g$convergence);print(g$singular)
 cat("NLMM\n");print(n$table);print(n$intervals);print(n$variance)
 cat("Alternative starts: maximum coefficient difference\n")
 print(max(abs(nlme::fixef(n$model)-nlme::fixef(n2$model))))
 print(sessionInfo())},file=file.path(out,"mixed-types-log.txt"))
