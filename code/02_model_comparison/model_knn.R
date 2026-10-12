# ============================================================================
# model_knn.R — K-Nearest Neighbors regression, equal tuning
#
# Appends one row to results/tables/model_comparison.csv (Table 3).
# ============================================================================
source("code/common.R")

r2v <- rmsev <- maev <- numeric(50)
rowi <- 0
for (rep in 1:10) for (f in 1:5) {
  rowi <- rowi + 1
  te <- which(outer_folds[, rep] == f); tr <- which(outer_folds[, rep] != f)
  p <- tune_and_predict(tr, te, grid_knn, fit_knn)
  r2v[rowi] <- r2_conv(Y[te], p)
  rmsev[rowi] <- sqrt(mean((Y[te] - p)^2))
  maev[rowi] <- mean(abs(Y[te] - p))
}
cat(sprintf("KNN: R2=%.3f+-%.3f  RMSE=%.0f+-%.0f  MAE=%.0f+-%.0f\n",
    mean(r2v, na.rm=TRUE), sd(r2v, na.rm=TRUE), mean(rmsev), sd(rmsev), mean(maev), sd(maev)))

row_out <- data.frame(
  Model = "KNN",
  Grid = "k in {1,3,5,7,9,11,15}",
  R2 = sprintf("%.2f +- %.2f", mean(r2v, na.rm=TRUE), sd(r2v, na.rm=TRUE)),
  RMSE = sprintf("%.0f +- %.0f", mean(rmsev), sd(rmsev)),
  MAE = sprintf("%.0f +- %.0f", mean(maev), sd(maev)))
write.table(row_out, "results/tables/model_comparison.csv", sep = ",", row.names = FALSE,
            col.names = !file.exists("results/tables/model_comparison.csv"), append = TRUE)
