# ============================================================================
# hyperparameters.R — Operating hyperparameters and nested-CV check
#
# 1. Full-data selection: every cell of the 200-combo grid is evaluated by
#    5x5 CV on the full sample; the best cell (C=10, gamma=0.20, eps=0.05)
#    is used as the fixed operating hyperparameters of the main analysis.
# 2. Nested-CV check: per-fold tuning (10 outer x 3 inner folds) is compared
#    with the fixed operating hyperparameters on the same outer folds, to
#    show that grid selection does not substantially inflate the in-sample
#    estimate (Section 3.3 of the manuscript).
# ============================================================================
source("code/common.R")

# ---- 1. Full-data grid selection ------------------------------------------
cat("=== Full-data grid selection (5x5 CV per cell) ===\n")
best_s <- -Inf; best_g <- NA
r2_all <- numeric(nrow(grid_svr))
for (g in seq_len(nrow(grid_svr))) {
  r2v <- numeric(25); rowi <- 0
  for (rep in 1:5) { set.seed(rep * 100 + 42); folds <- sample(rep(1:5, length.out = n))
    for (f in 1:5) {
      rowi <- rowi + 1
      ti <- which(folds == f); tr <- which(folds != f)
      p <- fit_svr(X[tr, , drop = FALSE], Y[tr], X[ti, , drop = FALSE],
                   data.frame(C = grid_svr$C[g], gamma = grid_svr$gamma[g], eps = grid_svr$eps[g]))
      r2v[rowi] <- r2(Y[ti], p)
    } }
  r2_all[g] <- mean(r2v, na.rm = TRUE)
  if (r2_all[g] > best_s) { best_s <- r2_all[g]; best_g <- g }
}
cat(sprintf("Best cell: C=%.1f gamma=%.2f eps=%.2f  R2=%.3f\n",
    grid_svr$C[best_g], grid_svr$gamma[best_g], grid_svr$eps[best_g], best_s))
op <- which(grid_svr$C == 10 & grid_svr$gamma == 0.2 & grid_svr$eps == 0.05)
cat(sprintf("Operating (10, 0.20, 0.05): R2=%.3f  rank %d of %d\n",
    r2_all[op], sum(r2_all > r2_all[op]) + 1, nrow(grid_svr)))

# ---- 2. Nested-CV check (10 outer x 3 inner) --------------------------------
cat("\n=== Nested-CV check ===\n")
r2n <- r2f <- numeric(50); rowi <- 0
for (rep in 1:10) for (f in 1:5) {
  rowi <- rowi + 1
  te <- which(outer_folds[, rep] == f); tr <- which(outer_folds[, rep] != f)
  pn <- tune_and_predict(tr, te, grid_svr, fit_svr)
  pf <- fit_svr(X[tr, , drop = FALSE], Y[tr], X[te, , drop = FALSE],
                data.frame(C = 10, gamma = 0.2, eps = 0.05))
  r2n[rowi] <- r2_conv(Y[te], pn)
  r2f[rowi] <- r2_conv(Y[te], pf)
}
cat(sprintf("Per-fold tuning (nested):  R2=%.3f+-%.3f\n", mean(r2n), sd(r2n)))
cat(sprintf("Fixed operating params:    R2=%.3f+-%.3f\n", mean(r2f), sd(r2f)))
cat(sprintf("Difference: %.3f\n", mean(r2f) - mean(r2n)))
