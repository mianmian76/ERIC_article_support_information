# ============================================================================
# importance_lopo.R — Subset sensitivity and permutation importance under
# leave-one-province-out cross-validation (Reviewer 1, round 2)
#
# The dimension subsets and permutation importances in the manuscript are
# computed under random cross-validation, where the model mostly recovers
# province identity. This script recomputes both under LOPO, where a province
# is entirely absent from training, to see whether the apparent importance of
# the indicators (in particular per capita GDP) survives.
# ============================================================================
source("code/common.R")

op <- data.frame(C = 10, gamma = 0.2, eps = 0.05)

lopo_predict <- function(Xu, y, perm_col = NULL) {
  pred <- numeric(n)
  for (p in unique(prov)) {
    te <- which(prov == p); tr <- which(prov != p)
    Xte <- Xu[te, , drop = FALSE]
    if (!is.null(perm_col)) Xte[, perm_col] <- sample(Xte[, perm_col])
    pred[te] <- fit_svr(Xu[tr, , drop = FALSE], y[tr], Xte, op)
  }
  pred
}

# ---- 1. Subset sensitivity under LOPO --------------------------------------
subs <- list(Full = 1:6, Economic = c(1, 3), Environmental = c(2, 5), Cost = c(4, 6))
sub_lopo_r2 <- numeric(length(subs))
names(sub_lopo_r2) <- names(subs)
cat("Subset sensitivity under LOPO (pooled R2):\n")
for (nm in names(subs)) {
  cols <- subs[[nm]]
  pred <- lopo_predict(X[, cols, drop = FALSE], Y)
  sub_lopo_r2[nm] <- r2(Y, pred)
  cat(sprintf("  %-13s R2=%.3f\n", nm, sub_lopo_r2[nm]))
}

# ---- 2. Per-feature permutation importance under LOPO ----------------------
feat_en <- c("Per capita GDP", "Emission share", "Industrial profits",
             "Treatment inv./GDP", "Environmental quality", "Treatment facility share")
base <- r2(Y, lopo_predict(X, Y))
cat(sprintf("\nPermutation importance under LOPO (base pooled R2=%.3f):\n", base))
drops <- numeric(6)
for (j in 1:6) {
  pred_j <- lopo_predict(X, Y, perm_col = j)
  drops[j] <- base - r2(Y, pred_j)
  cat(sprintf("  %-22s R2=%.3f  drop=%.3f\n", feat_en[j], r2(Y, pred_j), drops[j]))
}

# For comparison, the random-CV permutation importance (from importance.csv)
imp <- read.csv("results/tables/importance.csv")
rcv <- subset(imp, type == "feature")
cat("\nRandom-CV permutation drops (manuscript Figure 3b):\n")
print(data.frame(feature = rcv$name, drop = round(rcv$value, 3)), row.names = FALSE)

# Write LOPO results for the figure scripts
sub_lopo <- data.frame(type = "dimension", name = names(sub_lopo_r2),
                       value = unname(sub_lopo_r2))
feat_lopo <- data.frame(type = "feature", name = feat_en, value = drops)
dir.create("results/tables", showWarnings = FALSE, recursive = TRUE)
write.csv(rbind(sub_lopo, feat_lopo), "results/tables/importance_lopo.csv", row.names = FALSE)
cat("\nSaved results/tables/importance_lopo.csv\n")
