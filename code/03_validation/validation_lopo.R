# ============================================================================
# validation_lopo.R — Leave-one-province-out cross-validation (fixed operating
# hyperparameters), plus the province-classifier diagnostic
#
# Outputs:
#   results/predictions/lopo.csv          predictions for all 89 records
#   console: pooled R2 / RMSE; per-province actual vs predicted means for the
#            five extreme provinces; province-classifier accuracy
# ============================================================================
source("code/common.R")

pred <- numeric(n)
for (p in unique(prov)) {
  te <- which(prov == p); tr <- which(prov != p)
  pred[te] <- fit_svr(X[tr, , drop = FALSE], Y[tr], X[te, , drop = FALSE],
                      data.frame(C = 10, gamma = 0.2, eps = 0.05))
}
cat(sprintf("LOPO: R2=%.3f  RMSE=%.0f\n", r2(Y, pred), sqrt(mean((Y - pred)^2))))
for (p in c("甘肃", "海南", "福建", "安徽", "浙江")) {
  ti <- which(prov == p)
  cat(sprintf("  %s: N=%d  actual mean=%.0f  pred mean=%.0f\n",
      p, length(ti), mean(Y[ti]), mean(pred[ti])))
}

# Province classifier: does the six-indicator set identify the province?
suppressMessages(library(randomForest))
clf <- randomForest(x = X, y = as.factor(prov), ntree = 500)
acc <- mean(predict(clf) == prov)
cat(sprintf("Province classifier accuracy: %.1f%%\n", 100 * acc))

# Other models under LOPO (the collapse is not specific to SVR)
pred_rf <- numeric(n)
for (p in unique(prov)) {
  te <- which(prov == p); tr <- which(prov != p)
  rf <- randomForest(x = X[tr, ], y = Y[tr], ntree = 500, mtry = 3)
  pred_rf[te] <- predict(rf, X[te, ])
}
cat(sprintf("RF LOPO: R2=%.3f\n", r2(Y, pred_rf)))

set.seed(42)
pred_knn <- numeric(n)
for (p in unique(prov)) {
  te <- which(prov == p); tr <- which(prov != p)
  m <- train(x = as.data.frame(X[tr, ]), y = Y[tr], method = "knn",
             trControl = trainControl(method = "cv", number = 3), tuneLength = 3)
  pred_knn[te] <- predict(m, as.data.frame(X[te, ]))
}
cat(sprintf("KNN LOPO: R2=%.3f\n", r2(Y, pred_knn)))

# Log-transformed target under LOPO (robustness check, Section 5.3)
pred_lg <- numeric(n)
for (p in unique(prov)) {
  te <- which(prov == p); tr <- which(prov != p)
  Xtr <- scale(X[tr, ]); Xte <- scale(X[te, ], center = attr(Xtr, "scaled:center"), scale = attr(Xtr, "scaled:scale"))
  sv <- svm(x = as.data.frame(Xtr), y = log(Y[tr]), kernel = "radial", cost = 10, gamma = 0.2, epsilon = 0.05)
  pred_lg[te] <- exp(as.numeric(predict(sv, as.data.frame(Xte))))
}
cat(sprintf("Log-LOPO: R2=%.3f\n", r2(Y, pred_lg)))

dir.create("results/predictions", showWarnings = FALSE, recursive = TRUE)
write.csv(data.frame(Province = prov, Pollutant = pol, Year = yr,
                     Actual = Y, Predicted = pred),
          "results/predictions/lopo.csv", row.names = FALSE)
