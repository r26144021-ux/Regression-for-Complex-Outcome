# 在解壓縮後的總資料夾執行：
# source("cluster-survival-r/scripts/demo.R", encoding="UTF-8")
# 缺套件時先執行 install.packages(c("survival","lme4","geepack"))
# 亦可：Rscript cluster-survival-r/scripts/demo.R cluster-survival-r demo-results
args <- commandArgs(trailingOnly=TRUE)
root <- if(length(args)>0) args[1] else "cluster-survival-r"
out <- if(length(args)>1) args[2] else "demo-results"
dir.create(out,recursive=TRUE,showWarnings=FALSE)
source(file.path(root,"scripts","workflow.R"),encoding="UTF-8")
for(p in c("survival","lme4","geepack")) need_package(p)
library(survival)

# 1. Cox：與教材相同，只納入性別，原始 228 列皆可用。
d <- survival::lung
stopifnot(all(d$status %in% c(1,2)))
d$event <- as.integer(d$status==2)
d$sex <- factor(d$sex,levels=c(1,2),labels=c("Male","Female"))
cx <- fit_cox(d,Surv(time,event)~sex,"time","event")
write.csv(cx$table,file.path(out,"cox.csv"),row.names=FALSE)
write.csv(cx$ph$table,file.path(out,"cox-ph.csv"))
png(file.path(out,"cox-survival.png"),width=1100,height=700,res=120)
plot(survfit(cx$model,newdata=data.frame(sex=factor(c("Male","Female"),levels=levels(d$sex)))),
     col=c("#176b87","#da8b38"),lwd=2,xlab="Days",ylab="Estimated survival probability")
legend("topright",legend=c("Male","Female"),col=c("#176b87","#da8b38"),lwd=2,bty="n");dev.off()
png(file.path(out,"cox-ph.png"),width=1000,height=700,res=120);plot(cx$ph);dev.off()

# 2. LMM：18 位受試者，各 10 次；Reaction 毫秒，Days 為睡眠剝奪天數。
s <- lme4::sleepstudy
mx <- fit_mixed(s,Reaction~Days+(Days|Subject))
write.csv(mx$table,file.path(out,"mixed.csv"),row.names=FALSE)
write.csv(mx$variance,file.path(out,"mixed-variance.csv"),row.names=FALSE)
png(file.path(out,"mixed-diagnostics.png"),width=1200,height=600,res=120)
par(mfrow=c(1,2));plot(fitted(mx$model),residuals(mx$model),xlab="Fitted",ylab="Residuals");abline(h=0,lty=2)
qqnorm(residuals(mx$model));qqline(residuals(mx$model));dev.off()

# 3. Binary GEE：ohio 537 名兒童、4 次訪視，resp=1 為有症狀。
data("ohio",package="geepack")
o <- ohio
gx <- fit_gee(o,resp~age+smoke,"id","age",binomial(),"exchangeable")
gi <- fit_gee(o,resp~age+smoke,"id","age",binomial(),"independence")
write.csv(gx$table,file.path(out,"gee.csv"),row.names=FALSE)
write.csv(gi$table,file.path(out,"gee-independence.csv"),row.names=FALSE)
write.csv(rbind(exchangeable=gx$QIC,independence=gi$QIC),file.path(out,"gee-qic.csv"))

capture.output({
 cat("Cox\n");print(cx$table);print(cx$ph);cat("n / events",cx$n,cx$events,"\n")
 cat("Mixed\n");print(mx$table);print(mx$variance);print(mx$convergence);cat("singular",mx$singular,"\n")
 cat("GEE\n");print(gx$table);cat("clusters",gx$clusters,"error",gx$model$geese$error,"\n");print(gx$QIC)
 cat("GEE sensitivity\n");print(gi$table);print(gi$QIC)
 print(sessionInfo())
},file=file.path(out,"execution-log.txt"))
saveRDS(list(cox=cx,mixed=mx,gee=gx),file.path(out,"models.rds"))
cat("完成；結果位於：",normalizePath(out),"\n")
