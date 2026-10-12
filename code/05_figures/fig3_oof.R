# ============================================================================
# fig3_oof.R — Figure 3: out-of-fold predicted vs actual prices under random
# cross-validation (reads results/predictions/random_cv.csv)
# ============================================================================
suppressMessages(library(ggplot2))
source("code/05_figures/fig_labels.R")
pr <- read.csv("results/predictions/random_cv.csv")
df <- data.frame(Actual = pr$Actual, Predicted = pr$Predicted)
p <- ggplot(df, aes(Actual, Predicted)) +
  geom_point(size = 2, alpha = 0.7, color = "#2E86C1") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  annotate("text", x = max(df$Actual) * 0.9, y = 0,
           label = "r² = 0.70\nRMSE = 1352", size = 4, hjust = 1) +
  # Thousands separators only from five digits up (2500, not 2,500)
  scale_x_continuous(labels = comma_5plus) +
  scale_y_continuous(labels = comma_5plus) +
  coord_cartesian(xlim = c(0, max(df$Actual)), ylim = c(0, max(df$Actual)), expand = FALSE) +
  theme_classic(base_size = 11) +
  theme(panel.grid = element_blank(),
        panel.border = element_rect(fill = NA, color = "black", linewidth = 1)) +
  labs(x = "Actual price (CNY/(ton·yr))", y = "Predicted price (CNY/(ton·yr))")
dir.create("results/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("results/figures/fig3_oof.png", p, width = 6.5, height = 5.5, dpi = 300)
cat("fig2 saved\n")
