# ============================================================================
# model_elasticnet.R — Elastic Net, equal tuning
#
# Appends one row to results/tables/model_comparison.csv (Table 3).
# Protocol identical to model_svr.R; lambda is selected by inner cross-
# validation inside cv.glmnet.
# ============================================================================
source("code/common.R")

r2v <- rmsev <- maev <- numeric(50)
rowi <- 0
for (rep in 1:10) for (f in 1:5) {
  rowi <- rowi + 1
  te <- which(outer_folds[, rep] == f); tr <- which(outer_folds[, rep] != f)
  p <- tune_and_predict(tr, te, grid_en, fit_en)
  r2v[rowi] <- r2_conv(Y[te], p)
  rmsev[rowi] <- sqrt(mean((Y[te] - p)^2))
  maev[rowi] <- mean(abs(Y[te] - p))
}
# Elastic Net collapses to a constant prediction on some folds (cross-validated
# lambda shrinks all coefficients to zero); all metrics are based on the folds
# with valid predictions only (see the note under Table 3 of the manuscript).
ok <- !is.na(r2v)
cat(sprintf("Elastic Net: R2=%.3f+-%.3f (n=%d folds)  RMSE=%.0f+-%.0f  MAE=%.0f+-%.0f\n",
    mean(r2v[ok]), sd(r2v[ok]), sum(ok), mean(rmsev[ok]), sd(rmsev[ok]), mean(maev[ok]), sd(maev[ok])))

row_out <- data.frame(
  Model = "Elastic Net",
  Grid = "alpha in {0,0.25,0.5,0.75,1}; lambda by inner CV",
  R2 = sprintf("%.2f +- %.2f", mean(r2v[ok]), sd(r2v[ok])),
  RMSE = sprintf("%.0f +- %.0f", mean(rmsev[ok]), sd(rmsev[ok])),
  MAE = sprintf("%.0f +- %.0f", mean(maev[ok]), sd(maev[ok])))
write.table(row_out, "results/tables/model_comparison.csv", sep = ",", row.names = FALSE,
            col.names = !file.exists("results/tables/model_comparison.csv"), append = TRUE)
