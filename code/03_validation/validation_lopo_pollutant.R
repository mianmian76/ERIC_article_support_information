# ============================================================================
# validation_lopo_pollutant.R — Leave-one-pollutant-out cross-validation
# (fixed operating hyperparameters)
#
# Outputs:
#   results/predictions/lopo_pollutant.csv   predictions for all 89 records
#   console: pooled R2 and per-pollutant R2
# ============================================================================
source("code/common.R")

pred <- numeric(n)
for (p in unique(pol)) {
  te <- which(pol == p); tr <- which(pol != p)
  pred[te] <- fit_svr(X[tr, , drop = FALSE], Y[tr], X[te, , drop = FALSE],
                      data.frame(C = 10, gamma = 0.2, eps = 0.05))
}
cat(sprintf("LOPO-pollutant overall: R2=%.3f\n", r2(Y, pred)))
for (p in c("SO2", "NOX", "COD", "氨氮", "VOCs")) {
  ti <- which(pol == p)
  cat(sprintf("  %s (N=%d): R2=%.3f  MAE=%.0f\n", p, length(ti), r2(Y[ti], pred[ti]), mean(abs(Y[ti] - pred[ti]))))
}

dir.create("results/predictions", showWarnings = FALSE, recursive = TRUE)
write.csv(data.frame(Province = prov, Pollutant = pol, Year = yr,
                     Actual = Y, Predicted = pred),
          "results/predictions/lopo_pollutant.csv", row.names = FALSE)
