# ============================================================================
# kernel_comparison.R — SVR with linear / polynomial / sigmoid kernels,
# equal tuning (same protocol as model_svr.R)
#
# Appends rows to results/tables/model_comparison.csv (Table 3). The RBF row
# is written by model_svr.R.
# ============================================================================
source("code/common.R")

fit_svr_kernel <- function(Xtr, ytr, Xte, par, kk) {
  Xs <- scale(Xtr); Xte_s <- scale(Xte, center = attr(Xs, "scaled:center"), scale = attr(Xs, "scaled:scale"))
  m <- svm(x = as.data.frame(Xs), y = ytr, kernel = kk, cost = par$C, gamma = par$gamma, epsilon = par$eps)
  as.numeric(predict(m, as.data.frame(Xte_s)))
}

for (kk in c("linear", "polynomial", "sigmoid")) {
  fitfun <- function(Xtr, ytr, Xte, par) fit_svr_kernel(Xtr, ytr, Xte, par, kk)
  r2v <- rmsev <- maev <- numeric(50)
  rowi <- 0
  for (rep in 1:10) for (f in 1:5) {
    rowi <- rowi + 1
    te <- which(outer_folds[, rep] == f); tr <- which(outer_folds[, rep] != f)
    p <- tune_and_predict(tr, te, grid_svr, fitfun)
    r2v[rowi] <- r2_conv(Y[te], p)
    rmsev[rowi] <- sqrt(mean((Y[te] - p)^2))
    maev[rowi] <- mean(abs(Y[te] - p))
  }
  cat(sprintf("SVR (%s): R2=%.3f+-%.3f  RMSE=%.0f+-%.0f  MAE=%.0f+-%.0f\n",
      kk, mean(r2v, na.rm=TRUE), sd(r2v, na.rm=TRUE), mean(rmsev), sd(rmsev), mean(maev), sd(maev)))
  row_out <- data.frame(
    Model = paste0("SVR (", kk, " kernel)"),
    Grid = "same C/gamma/eps grid as SVR (RBF)",
    R2 = sprintf("%.2f +- %.2f", mean(r2v, na.rm=TRUE), sd(r2v, na.rm=TRUE)),
    RMSE = sprintf("%.0f +- %.0f", mean(rmsev), sd(rmsev)),
    MAE = sprintf("%.0f +- %.0f", mean(maev), sd(maev)))
  write.table(row_out, "results/tables/model_comparison.csv", sep = ",", row.names = FALSE,
              col.names = !file.exists("results/tables/model_comparison.csv"), append = TRUE)
}
