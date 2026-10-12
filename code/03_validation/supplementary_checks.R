# ============================================================================
# supplementary_checks.R — Standard R2 and RMSE for the validation designs
#
# 1. Standard R2 (1 - SSE/SST) for each of the four validation designs, and
#    RMSE for the province bootstrap and leave-one-pollutant-out rows so that
#    the empty cells in Table 4 can be filled.
# ============================================================================
source("code/common.R")

r2_conv <- function(y, pred) 1 - sum((y - pred)^2) / sum((y - mean(y))^2)

# ---- 1. Random CV: pooled predictions, conventional R2 and RMSE -------------
rcv <- read.csv("results/predictions/random_cv.csv")
cat(sprintf("Random CV:            cor2=%.3f  convR2=%.3f  RMSE(pooled)=%.0f\n",
    r2(rcv$Actual, rcv$Predicted), r2_conv(rcv$Actual, rcv$Predicted),
    sqrt(mean((rcv$Actual - rcv$Predicted)^2))))

# ---- 2. LOPO: conventional R2 and RMSE --------------------------------------
lopo <- read.csv("results/predictions/lopo.csv")
cat(sprintf("LOPO:                 cor2=%.3f  convR2=%.3f  RMSE=%.0f\n",
    r2(lopo$Actual, lopo$Predicted), r2_conv(lopo$Actual, lopo$Predicted),
    sqrt(mean((lopo$Actual - lopo$Predicted)^2))))

# ---- 3. Province bootstrap: per-draw conventional R2 and RMSE ---------------
set.seed(42)
n_draws <- 500
r2b_c <- r2b_v <- rmseb <- numeric(n_draws)
for (b in 1:n_draws) {
  draw <- sample(unique(prov), replace = TRUE)
  tr <- which(prov %in% draw); te <- which(!(prov %in% draw))
  if (length(te) == 0) { r2b_c[b] <- NA; r2b_v[b] <- NA; rmseb[b] <- NA; next }
  p <- fit_svr(X[tr, , drop = FALSE], Y[tr], X[te, , drop = FALSE],
               data.frame(C = 10, gamma = 0.2, eps = 0.05))
  r2b_c[b] <- r2_conv(Y[te], p)
  r2b_v[b] <- r2(Y[te], p)
  rmseb[b] <- sqrt(mean((Y[te] - p)^2))
}
cat(sprintf("Bootstrap:            cor2 median=%.3f  convR2 median=%.3f  RMSE median=%.0f\n",
    median(r2b_v, na.rm = TRUE), median(r2b_c, na.rm = TRUE), median(rmseb, na.rm = TRUE)))

# ---- 4. LOPO-pollutant: conventional R2 and RMSE ----------------------------
lop <- read.csv("results/predictions/lopo_pollutant.csv")
cat(sprintf("LOPO-pollutant:       cor2=%.3f  convR2=%.3f  RMSE=%.0f\n",
    r2(lop$Actual, lop$Predicted), r2_conv(lop$Actual, lop$Predicted),
    sqrt(mean((lop$Actual - lop$Predicted)^2))))
