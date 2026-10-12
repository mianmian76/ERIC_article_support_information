# ============================================================================
# positive_control.R — Positive control simulation
#
# The argument rests on a null result, so we verify that the design can detect
# a transferable pricing rule when one exists. Simulated prices are drawn from
# a known smooth function of the six indicators plus realistic noise, holding
# the actual province-pollutant-year design fixed, and the same
# leave-one-province-out SVR protocol (fixed operating hyperparameters) is
# applied. If LOPO recovers the rule, the null result on real data cannot be
# attributed to the small sample.
#
# Rule: log price = 7.5 + b' z, where z are the six standardized indicators.
# Coefficients are moderate and the noise level is set so the rule explains
# about two thirds of the variance, comparable to what a working pricing
# model would achieve. Five replicates per noise level.
# ============================================================================
source("code/common.R")

op <- data.frame(C = 10, gamma = 0.2, eps = 0.05)
Z <- scale(X)

# coefficients on standardized indicators (GDP, emission share, profits,
# investment/GDP, quality rate, facility share)
b <- c(0.6, 0.5, 0.3, -0.2, -0.4, 0.3)

run_lopo <- function(y) {
  pred <- numeric(n)
  for (p in unique(prov)) {
    te <- which(prov == p); tr <- which(prov != p)
    pred[te] <- fit_svr(X[tr, , drop = FALSE], y[tr], X[te, , drop = FALSE], op)
  }
  r2(y, pred)
}

set.seed(42)
for (noise_frac in c(0.6, 1.0)) {   # noise SD as fraction of signal SD
  res <- numeric(5)
  for (rep in 1:5) {
    f <- Z %*% b
    y_log <- 7.5 + f + rnorm(n, 0, noise_frac * sd(f))
    res[rep] <- run_lopo(y_log)
  }
  cat(sprintf("Noise frac %.1f: true-rule R2=%.2f  LOPO R2 mean=%.3f (reps: %s)\n",
      noise_frac, 1 / (1 + noise_frac^2), mean(res),
      paste(sprintf("%.3f", res), collapse = ", ")))
}
