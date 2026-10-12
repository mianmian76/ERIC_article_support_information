# ============================================================================
# fig5_importance.R — Figure 3b: per-feature permutation importance under
# random cross-validation versus leave-one-province-out.
# ============================================================================
suppressMessages(library(ggplot2))
imp <- read.csv("results/tables/importance.csv")
feat_rcv <- subset(imp, type == "feature")
lopo <- read.csv("results/tables/importance_lopo.csv")
feat_lopo <- subset(lopo, type == "feature")

order_nm <- feat_rcv$name[order(feat_rcv$value)]
df <- rbind(
  data.frame(name = feat_rcv$name, value = feat_rcv$value, Design = "Random CV"),
  data.frame(name = feat_lopo$name, value = feat_lopo$value, Design = "LOPO")
)
df$name <- factor(df$name, levels = order_nm)
df$Design <- factor(df$Design, levels = c("Random CV", "LOPO"))

p <- ggplot(df, aes(value, name, fill = Design)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.65) +
  # Round |value| < 0.005 to zero, so permutation drops that are numerically
  # zero are not printed as "-0.00"; negatives get a true minus sign.
  geom_text(aes(label = { v <- ifelse(abs(value) < 0.005, 0, value)
                         sub("^-", "\u2212", sprintf("%.2f", v)) }),
            position = position_dodge(width = 0.7), hjust = -0.3, size = 3.0) +
  scale_fill_manual(values = c("Random CV" = "#2E86C1", "LOPO" = "#E74C3C")) +
  coord_cartesian(xlim = c(0, 0.55), expand = FALSE, clip = "off") +
  theme_classic(base_size = 10) +
  theme(legend.position = "bottom", legend.key = element_blank(),
        panel.border = element_rect(fill = NA, color = "black", linewidth = 0.6)) +
  labs(x = "r\u00b2 drop under permutation", y = "", fill = "")
dir.create("results/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("results/figures/fig5_importance.png", p, width = 5, height = 3.8, dpi = 300)
cat("fig5 saved\n")
