# ============================================================================
# sensitivity_importance.R — Subset sensitivity and per-feature permutation
# importance (fixed operating hyperparameters, 10x5 folds, pooled out-of-fold
# metric; r2 = squared correlation, consistent with the manuscript convention)
#
# Outputs results/tables/importance.csv (Figure 3) and prints the numbers
# reported in Section 4.1.
# ============================================================================
source("code/common.R")

op <- data.frame(C = 10, gamma = 0.2, eps = 0.05)

# ---- pooled out-of-fold predictions for a given feature set -----------------
oof_predict <- function(cols, perm_col = NULL) {
  pred <- numeric(n); cnt <- numeric(n)
  for (rep in 1:10) for (f in 1:5) {
    te <- which(outer_folds[, rep] == f); tr <- which(outer_folds[, rep] != f)
    Xte <- X[te, cols, drop = FALSE]
    if (!is.null(perm_col)) Xte[, perm_col] <- sample(Xte[, perm_col])
    p <- fit_svr(X[tr, cols, drop = FALSE], Y[tr], Xte, op)
    pred[te] <- pred[te] + p
    cnt[te] <- cnt[te] + 1
  }
  pred / cnt
}

# ---- Subset sensitivity -----------------------------------------------------
subs <- list(Full = 1:6, Economic = c(1, 3), Environmental = c(2, 5), Cost = c(4, 6))
sub_r2 <- sapply(subs, function(cols) r2(Y, oof_predict(cols)))
cat("Subset sensitivity (pooled r2):\n"); print(round(sub_r2, 3))

# ---- Per-feature permutation importance (pooled) ----------------------------
feat_en <- c("Per capita GDP", "Emission share", "Industrial profits",
             "Treatment inv./GDP", "Environmental quality", "Treatment facility share")
base_r2 <- sub_r2["Full"]
drops <- numeric(6)
for (j in 1:6) {
  drops[j] <- base_r2 - r2(Y, oof_predict(1:6, perm_col = j))
}
cat("Permutation importance (pooled r2 drop):\n")
print(data.frame(feature = feat_en, drop = round(drops, 3)))

dir.create("results/tables", showWarnings = FALSE, recursive = TRUE)
write.csv(rbind(
  data.frame(type = "dimension", name = names(sub_r2), value = unname(sub_r2)),
  data.frame(type = "feature", name = feat_en, value = unname(drops))),
  "results/tables/importance.csv", row.names = FALSE)
