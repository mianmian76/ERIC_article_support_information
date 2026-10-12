# ============================================================================
# descriptives.R — Table 1, two-factor variance decomposition, and baselines
#
# Outputs:
#   results/tables/table1.csv   per-pollutant descriptive statistics (Table 1)
#   console: net contributions of province and pollutant to price variance;
#            province-mean baseline (leave-one-out) and pollutant-median
#            baseline (leave-self-out)
# ============================================================================
source("code/common.R")

# ---- Table 1: descriptive statistics by pollutant --------------------------
pol_order <- c("COD", "氨氮", "SO2", "NOX", "VOCs")
tab1 <- do.call(rbind, lapply(pol_order, function(p) {
  y <- Y[pol == p]
  data.frame(Pollutant = p, n = length(y), Mean = mean(y), SD = sd(y),
             Min = min(y), Median = median(y), Max = max(y))
}))
dir.create("results/tables", showWarnings = FALSE, recursive = TRUE)
write.csv(tab1, "results/tables/table1.csv", row.names = FALSE)
print(tab1)

# ---- Two-factor variance decomposition --------------------------------------
# Province and pollutant are overlapping groupings; report the net (Type II)
# contributions of each factor: the increment in R2 when a factor is added
# after the other.
r2_prov <- summary(lm(Y ~ factor(prov)))$r.squared
r2_pol  <- summary(lm(Y ~ factor(pol)))$r.squared
r2_full <- summary(lm(Y ~ factor(prov) + factor(pol)))$r.squared
cat(sprintf("Joint R2 (province + pollutant): %.0f%%\n", 100 * r2_full))
cat(sprintf("Net contribution of province (after pollutant): %.1f%%\n", 100 * (r2_full - r2_pol)))
cat(sprintf("Net contribution of pollutant (after province): %.1f%%\n", 100 * (r2_full - r2_prov)))

# ---- Baselines ---------------------------------------------------------------
# Leave-one-out province-mean baseline: each record is predicted by the mean of
# the other records of its province (no in-sample advantage over the model).
pred_loo <- numeric(n)
for (i in seq_len(n)) {
  j <- which(prov == prov[i] & seq_len(n) != i)
  pred_loo[i] <- mean(Y[j])
}
cat(sprintf("Province-mean baseline (leave-one-out): R2=%.3f\n", r2(Y, pred_loo)))

# Pollutant-median baseline (leave-self-out).
pred_med <- numeric(n)
for (i in seq_len(n)) {
  j <- which(pol == pol[i] & seq_len(n) != i)
  pred_med[i] <- median(Y[j])
}
cat(sprintf("Pollutant-median baseline (leave-self-out): R2=%.3f\n", r2(Y, pred_med)))
