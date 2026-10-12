# ============================================================================
# fig8_forest.R — Figure 8: forest plot of indicator-price correlations
# (reads results/tables/correlations.csv)
# ============================================================================
suppressMessages(library(ggplot2))
cor <- read.csv("results/tables/correlations.csv")
ci <- function(r, m) { z <- atanh(r); se <- 1 / sqrt(m - 3); c(tanh(z - 1.96 * se), tanh(z + 1.96 * se)) }
rows <- list()
for (i in seq_len(nrow(cor))) {
  cp <- ci(cor$Pooled_r[i], 89); cb <- ci(cor$Between_r[i], 18)
  rows[[i]] <- data.frame(Indicator = cor$Indicator_EN[i],
                          Level = c("Record-level", "Province-level"),
                          r = c(cor$Pooled_r[i], cor$Between_r[i]),
                          lo = c(cp[1], cb[1]), hi = c(cp[2], cb[2]))
}
df <- do.call(rbind, rows)
df$Indicator <- factor(df$Indicator, levels = rev(unique(df$Indicator)))
p <- ggplot(df, aes(r, Indicator, color = Level)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(aes(shape = Level), size = 2.6, position = position_dodge(width = 0.55)) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.25,
                 position = position_dodge(width = 0.55), linewidth = 0.5) +
  scale_color_manual(values = c("#2E86C1", "#E74C3C")) +
  scale_shape_manual(values = c(16, 17)) +
  # Negative axis labels carry a true minus sign (U+2212), not a hyphen
  scale_x_continuous(labels = function(v) sub("^-", "\u2212", sprintf("%.1f", v))) +
  coord_cartesian(xlim = c(-0.8, 0.8)) +
  theme_classic(base_size = 11) + theme(legend.position = "bottom",
      panel.border = element_rect(fill = NA, color = "black", linewidth = 1)) +
  labs(x = "Pearson correlation with price (95% CI)", y = "", color = "", shape = "")
dir.create("results/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("results/figures/fig8_forest.png", p, width = 7.5, height = 5.5, dpi = 300)
cat("fig6 saved\n")
