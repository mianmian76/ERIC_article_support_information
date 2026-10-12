# ============================================================================
# fig6_validation.R — Figure 6: R2 across the four validation designs
#
# The four values are the reported results of the validation_*.R scripts
# (deterministic under the fixed seeds of common.R):
#   random CV 0.69, LOPO 0.035, bootstrap median 0.066, LOPO-pollutant 0.66
# ============================================================================
suppressMessages(library(ggplot2))
val <- data.frame(
  Design = factor(c("Random 10×5-fold CV", "Leave-one-province-out",
                    "Province bootstrap (median)", "Leave-one-pollutant-out"),
                  levels = c("Random 10×5-fold CV", "Leave-one-province-out",
                             "Province bootstrap (median)", "Leave-one-pollutant-out")),
  R2 = c(0.696, -0.405, -0.375, 0.644))
p <- ggplot(val, aes(Design, R2, fill = Design)) +
  geom_col(width = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.4) +
  # Negative values carry a true minus sign (U+2212), not a hyphen
  geom_text(aes(label = sub("^-", "\u2212", sprintf("%.3f", R2))),
            vjust = ifelse(val$R2 >= 0, -0.5, 1.5), size = 4) +
  scale_y_continuous(labels = function(v) sub("^-", "\u2212", sprintf("%.1f", v))) +
  scale_fill_manual(values = c("#E74C3C", "#F39C12", "#7F8C8D", "#2E86C1")) +
  coord_cartesian(ylim = c(-0.55, 0.85)) +
  theme_classic(base_size = 11) + theme(legend.position = "none",
      panel.border = element_rect(fill = NA, color = "black", linewidth = 1),
      axis.text.x = element_text(angle = 15, hjust = 1)) +
  labs(x = "", y = "R²")
dir.create("results/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("results/figures/fig6_validation.png", p, width = 6.5, height = 4.5, dpi = 300)
cat("fig4 saved\n")
