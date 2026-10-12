# ============================================================================
# validation_random_cv.R — Random 10x5-fold cross-validation (fixed operating
# hyperparameters)
#
# Outputs:
#   results/predictions/random_cv.csv   pooled out-of-fold predictions
#   console: R2, RMSE, MAE; median absolute deviation and share of records
#            within 500 / 1000 CNY (Section 4.1)
# ============================================================================
source("code/common.R")

pred <- numeric(n); r2v <- rmsev <- maev <- numeric(50)
rowi <- 0
for (rep in 1:10) for (f in 1:5) {
  rowi <- rowi + 1
  te <- which(outer_folds[, rep] == f); tr <- which(outer_folds[, rep] != f)
  p <- fit_svr(X[tr, , drop = FALSE], Y[tr], X[te, , drop = FALSE],
               data.frame(C = 10, gamma = 0.2, eps = 0.05))
  pred[te] <- pred[te] + p
  r2v[rowi] <- r2(Y[te], p)
  rmsev[rowi] <- sqrt(mean((Y[te] - p)^2))
  maev[rowi] <- mean(abs(Y[te] - p))
}
pred <- pred / 10
cat(sprintf("Random CV: R2=%.3f+-%.3f  RMSE=%.0f+-%.0f  MAE=%.0f+-%.0f\n",
    mean(r2v), sd(r2v), mean(rmsev), sd(rmsev), mean(maev), sd(maev)))
dev <- abs(Y - pred)
cat(sprintf("OOF median abs dev = %.0f; within 500 = %.1f%%; within 1000 = %.1f%%\n",
    median(dev), 100 * mean(dev <= 500), 100 * mean(dev <= 1000)))

dir.create("results/predictions", showWarnings = FALSE, recursive = TRUE)
write.csv(data.frame(Province = prov, Pollutant = pol, Year = yr,
                     Actual = Y, Predicted = pred),
          "results/predictions/random_cv.csv", row.names = FALSE)
