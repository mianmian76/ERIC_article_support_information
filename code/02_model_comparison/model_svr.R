# ============================================================================
# model_svr.R — Support Vector Regression (RBF kernel), equal tuning
#
# Appends one row to results/tables/model_comparison.csv (Table 3).
# Protocol: same 10x5 outer folds as every other script; hyperparameters are
# selected on each outer training fold by inner 3-fold CV over the 200-cell
# C x gamma x eps grid, without touching the outer test fold.
# ============================================================================
source("code/common.R")

r2v <- rmsev <- maev <- numeric(50)
rowi <- 0
for (rep in 1:10) for (f in 1:5) {
  rowi <- rowi + 1
  te <- which(outer_folds[, rep] == f); tr <- which(outer_folds[, rep] != f)
  p <- tune_and_predict(tr, te, grid_svr, fit_svr)
  r2v[rowi] <- r2_conv(Y[te], p)
  rmsev[rowi] <- sqrt(mean((Y[te] - p)^2))
  maev[rowi] <- mean(abs(Y[te] - p))
}
cat(sprintf("SVR (RBF): R2=%.3f+-%.3f  RMSE=%.0f+-%.0f  MAE=%.0f+-%.0f\n",
    mean(r2v, na.rm=TRUE), sd(r2v, na.rm=TRUE), mean(rmsev), sd(rmsev), mean(maev), sd(maev)))

row_out <- data.frame(
  Model = "SVR (RBF)",
  Grid = "C in {0.5,1,2,5,10,20,50,100}; gamma in {0.05,0.10,0.20,0.50,1.00}; eps in {0.01,0.05,0.10,0.20,0.50}",
  R2 = sprintf("%.2f +- %.2f", mean(r2v, na.rm=TRUE), sd(r2v, na.rm=TRUE)),
  RMSE = sprintf("%.0f +- %.0f", mean(rmsev), sd(rmsev)),
  MAE = sprintf("%.0f +- %.0f", mean(maev), sd(maev)))
write.table(row_out, "results/tables/model_comparison.csv", sep = ",", row.names = FALSE,
            col.names = !file.exists("results/tables/model_comparison.csv"), append = TRUE)
