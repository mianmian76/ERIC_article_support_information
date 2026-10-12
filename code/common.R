# ============================================================================
# common.R — Shared functions for the ERIC pricing analysis
suppressMessages({library(e1071); library(randomForest); library(glmnet); library(pls); library(caret)})
#
# Run order: run_all.R sets the working directory to the repository root and
# sources code/common.R first. All scripts then use relative paths such as
# "data/analysis_data.csv" and "results/...".
#
# This file defines:
#   - data loading (89-record cleaned analysis set)
#   - the fixed outer 10x5 fold partition shared by every script
#   - the inner 3-fold tuning helper used in the equal-tuning comparison
#   - the R2 metric used throughout (squared Pearson correlation)
# ============================================================================

# ---- Data ------------------------------------------------------------------
load_data <- function() {
  d <- read.csv("data/analysis_data.csv", fileEncoding = "UTF-8", check.names = FALSE)
  colnames(d) <- trimws(colnames(d))
  d
}

# The six model indicators (two per statutory dimension), in column order:
# per capita GDP, emission share, industrial profits, treatment investment/GDP,
# environmental quality rate, treatment facility share.
model_cols <- c(1, 6, 8, 9, 10, 11)

# R2 as used throughout the manuscript: squared Pearson correlation between
# observed and predicted values.
r2 <- function(y, pred) {
  if (length(unique(pred)) < 2) return(NA_real_)
  cor(y, pred)^2
}

# Coefficient of determination (1 - SSE/SST), the standard R2 definition.
r2_conv <- function(y, pred) {
  1 - sum((y - pred)^2) / sum((y - mean(y))^2)
}

# ---- Outer folds (identical for every model and validation script) ---------
# 10 repetitions of 5-fold CV. The same seed scheme is used by every script,
# so all models are evaluated on exactly the same folds.
make_outer_folds <- function(n) {
  folds <- matrix(NA_integer_, nrow = n, ncol = 10)
  for (rep in 1:10) {
    set.seed(rep * 100 + 42)
    folds[, rep] <- sample(rep(1:5, length.out = n))
  }
  folds
}

# ---- Inner 3-fold tuning helper --------------------------------------------
# Scores one hyperparameter cell by 3-fold CV on the training part only.
# fitfun(Xtr, ytr, Xte, par) returns predictions.
inner_score <- function(tr_idx, fitfun, par) {
  set.seed(999)
  inf <- sample(rep(1:3, length.out = length(tr_idx)))
  s <- numeric(3)
  for (k in 1:3) {
    iti <- tr_idx[which(inf == k)]
    itr <- tr_idx[which(inf != k)]
    p <- fitfun(X[itr, , drop = FALSE], Y[itr], X[iti, , drop = FALSE], par)
    s[k] <- r2(Y[iti], p)
  }
  if (all(is.na(s))) NA_real_ else mean(s, na.rm = TRUE)
}

# Selects the best grid cell on the training part by inner 3-fold CV, then
# refits with the winning hyperparameters and predicts the test part.
tune_and_predict <- function(tr_idx, te_idx, grid, fitfun) {
  best <- NULL; best_s <- -Inf
  for (g in seq_len(nrow(grid))) {
    par <- grid[g, , drop = FALSE]
    s <- inner_score(tr_idx, fitfun, par)
    if (!is.na(s) && s > best_s) { best_s <- s; best <- par }
  }
  if (is.null(best)) best <- grid[1, , drop = FALSE]
  fitfun(X[tr_idx, , drop = FALSE], Y[tr_idx], X[te_idx, , drop = FALSE], best)
}

# ---- Model grids -----------------------------------------------------------
grid_svr <- expand.grid(C = c(0.5, 1, 2, 5, 10, 20, 50, 100),
                        gamma = c(0.05, 0.10, 0.20, 0.50, 1.00),
                        eps = c(0.01, 0.05, 0.10, 0.20, 0.50))   # 200 cells
grid_rf  <- data.frame(mtry = 1:6)
grid_knn <- data.frame(k = c(1, 3, 5, 7, 9, 11, 15))
grid_en  <- data.frame(alpha = c(0, 0.25, 0.5, 0.75, 1))
grid_pls <- data.frame(ncomp = 1:6)

# ---- Model fitting functions (all operate on raw X; scaling inside) --------
fit_svr <- function(Xtr, ytr, Xte, par) {
  Xs <- scale(Xtr); Xte_s <- scale(Xte, center = attr(Xs, "scaled:center"), scale = attr(Xs, "scaled:scale"))
  m <- svm(x = as.data.frame(Xs), y = ytr, kernel = "radial", cost = par$C, gamma = par$gamma, epsilon = par$eps)
  as.numeric(predict(m, as.data.frame(Xte_s)))
}
fit_rf <- function(Xtr, ytr, Xte, par) {
  predict(randomForest(x = Xtr, y = ytr, ntree = 500, mtry = par$mtry), Xte)
}
fit_knn <- function(Xtr, ytr, Xte, par) {
  Xs <- scale(Xtr); Xte_s <- scale(Xte, center = attr(Xs, "scaled:center"), scale = attr(Xs, "scaled:scale"))
  m <- knnreg(x = as.data.frame(Xs), y = ytr, k = par$k)
  as.numeric(predict(m, as.data.frame(Xte_s)))
}
fit_en <- function(Xtr, ytr, Xte, par) {
  Xs <- scale(Xtr); Xte_s <- scale(Xte, center = attr(Xs, "scaled:center"), scale = attr(Xs, "scaled:scale"))
  set.seed(42)  # fix cv.glmnet's internal folds so results are reproducible
  m <- cv.glmnet(as.matrix(Xs), ytr, alpha = par$alpha, nfolds = 3)
  as.numeric(predict(m, as.matrix(Xte_s), s = "lambda.min"))
}
fit_pls <- function(Xtr, ytr, Xte, par) {
  Xs <- scale(Xtr); Xte_s <- scale(Xte, center = attr(Xs, "scaled:center"), scale = attr(Xs, "scaled:scale"))
  m <- plsr(y ~ ., data = data.frame(y = ytr, Xs), ncomp = par$ncomp)
  as.numeric(predict(m, as.data.frame(Xte_s), ncomp = par$ncomp))
}

# ---- Global data objects ----------------------------------------------------
d <- load_data()
Y <- as.numeric(d[["定价"]])
prov <- trimws(as.character(d[["省份"]]))
pol  <- trimws(as.character(d[["污染物"]]))
yr   <- d[["年份"]]
X <- as.data.frame(lapply(d[, 7:17], as.numeric))[, model_cols]
n <- nrow(X)
outer_folds <- make_outer_folds(n)
