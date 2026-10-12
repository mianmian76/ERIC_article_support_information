# ============================================================================
# paired_svr_rf.R — Equal-tuned paired comparison of SVR and Random Forest
#
# Both models are tuned per fold on the same outer folds (equal-tuning
# protocol), and the fold-level R2 difference is tested with a paired t-test.
# Reported in Section 3.3 (difference 0.057, 95% CI [0.018, 0.095]).
# ============================================================================
source("code/common.R")

r2s <- r2r <- numeric(50)
rowi <- 0
for (rep in 1:10) for (f in 1:5) {
  rowi <- rowi + 1
  te <- which(outer_folds[, rep] == f); tr <- which(outer_folds[, rep] != f)
  ps <- tune_and_predict(tr, te, grid_svr, fit_svr)
  pr <- tune_and_predict(tr, te, grid_rf, fit_rf)
  r2s[rowi] <- r2_conv(Y[te], ps)
  r2r[rowi] <- r2_conv(Y[te], pr)
}
d <- r2s - r2r
tt <- t.test(d)
cat(sprintf("Paired SVR-RF fold-level R2 diff: mean=%.3f  CI=[%.3f, %.3f]  p=%.4f\n",
    mean(d), tt$conf.int[1], tt$conf.int[2], tt$p.value))
