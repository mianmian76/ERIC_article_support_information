# ============================================================================
# cleaning_specs_robustness.R — LOPO robustness across alternative cleaning
# specifications
#
# Four specifications of the analysis sample are compared under
# leave-one-province-out cross-validation with the fixed operating
# hyperparameters (C = 10, gamma = 0.20, eps = 0.05):
#   1. Full raw set (109): only records with a missing price or missing
#      indicator values are dropped.
#   2. Deduplicated (97): specification 1 minus exact duplicates (identical
#      province, pollutant, year, and price).
#   3. Pollutant N >= 3 (100): specification 1 restricted to pollutants
#      observed at least three times.
#   4. Analysis set (89): N >= 3 and exact duplicates removed, the main
#      analysis sample used throughout the manuscript.
#
# Outputs:
#   results/tables/cleaning_specs.csv   LOPO R2, RMSE, and N per specification
#   console: the same table
# ============================================================================
source("code/common.R")

raw <- read.csv("data/raw_data.csv", fileEncoding = "UTF-8", check.names = FALSE)
colnames(raw) <- trimws(colnames(raw))

Y_all <- as.numeric(raw[["定价"]])
prov_all <- trimws(as.character(raw[["省份"]]))
pol_all <- trimws(as.character(raw[["污染物"]]))
yr_all <- raw[["年份"]]
X_all <- as.data.frame(lapply(raw[, 7:17], as.numeric))[, model_cols]
n_all <- nrow(X_all)

# ---- Specification definitions ----------------------------------------------
complete <- complete.cases(X_all) & !is.na(Y_all)
dup <- duplicated(paste(prov_all, pol_all, yr_all, Y_all, sep = "|"))
n3 <- pol_all %in% names(which(table(pol_all) >= 3))

specs <- list(
  "Full raw set (109)"        = which(complete),
  "Deduplicated (97)"         = which(complete & !dup),
  "Pollutant N>=3 (100)"      = which(complete & n3),
  "Analysis set (89)"         = which(complete & n3 & !dup)
)

# ---- LOPO evaluation per specification --------------------------------------
op <- data.frame(C = 10, gamma = 0.2, eps = 0.05)
rows <- list()
for (nm in names(specs)) {
  idx <- specs[[nm]]
  y <- Y_all[idx]; prov <- prov_all[idx]
  x <- X_all[idx, , drop = FALSE]
  pred <- numeric(length(idx))
  for (p in unique(prov)) {
    te <- which(prov == p); tr <- which(prov != p)
    pred[te] <- fit_svr(x[tr, , drop = FALSE], y[tr], x[te, , drop = FALSE], op)
  }
  r2v <- r2(y, pred)
  rmsev <- sqrt(mean((y - pred)^2))
  cat(sprintf("%-20s N=%3d  provinces=%2d  LOPO R2=%.3f  RMSE=%.0f\n",
              nm, length(idx), length(unique(prov)), r2v, rmsev))
  rows[[nm]] <- data.frame(Specification = nm, N = length(idx),
                           Provinces = length(unique(prov)),
                           LOPO_R2 = r2v, RMSE = rmsev)
}
out <- do.call(rbind, rows)
dir.create("results/tables", showWarnings = FALSE, recursive = TRUE)
write.csv(out, "results/tables/cleaning_specs.csv", row.names = FALSE)
cat("\nSaved results/tables/cleaning_specs.csv\n")
