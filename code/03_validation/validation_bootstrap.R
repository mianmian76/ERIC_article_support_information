# ============================================================================
# validation_bootstrap.R — Province-level bootstrap (500 draws, fixed
# operating hyperparameters)
#
# Each draw samples provinces with replacement; SVR is trained on the records
# of the sampled provinces and evaluated on the records of provinces that were
# not drawn. The console reports the distribution of the pooled R2.
# ============================================================================
source("code/common.R")

set.seed(42)
r2b <- numeric(500)
for (b in 1:500) {
  draw <- sample(unique(prov), replace = TRUE)
  tr <- which(prov %in% draw); te <- which(!(prov %in% draw))
  if (length(te) == 0) next
  p <- fit_svr(X[tr, , drop = FALSE], Y[tr], X[te, , drop = FALSE],
               data.frame(C = 10, gamma = 0.2, eps = 0.05))
  r2b[b] <- r2(Y[te], p)
}
cat(sprintf("Bootstrap: median=%.3f  mean=%.3f  Q10=%.3f  Q90=%.3f\n",
    median(r2b, na.rm = TRUE), mean(r2b, na.rm = TRUE),
    quantile(r2b, 0.10, na.rm = TRUE), quantile(r2b, 0.90, na.rm = TRUE)))
