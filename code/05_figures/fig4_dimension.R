# ============================================================================
# fig4_dimension.R — Figure 3a: dimension contribution (subset sensitivity)
# under random cross-validation versus leave-one-province-out (round 2).
# ============================================================================
suppressMessages(library(ggplot2))
imp <- read.csv("results/tables/importance.csv")
dim_rcv <- subset(imp, type == "dimension")
lopo <- read.csv("results/tables/importance_lopo.csv")
dim_lopo <- subset(lopo, type == "dimension")

order_nm <- dim_rcv$name[order(dim_rcv$value)]
df <- rbind(
  data.frame(name = dim_rcv$name, value = dim_rcv$value, Design = "Random CV"),
  data.frame(name = dim_lopo$name, value = dim_lopo$value, Design = "LOPO")
)
df$name <- factor(df$name, levels = order_nm)
df$Design <- factor(df$Design, levels = c("Random CV", "LOPO"))

p <- ggplot(df, aes(value, name, fill = Design)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.65) +
  geom_text(aes(label = sub("^-", "\u2212", sprintf("%.2f", value))),
            position = position_dodge(width = 0.7), hjust = -0.3, size = 3.0) +
  scale_fill_manual(values = c("Random CV" = "#2E86C1", "LOPO" = "#E74C3C")) +
  coord_cartesian(xlim = c(0, 0.85), expand = FALSE, clip = "off") +
  theme_classic(base_size = 10) +
  theme(legend.position = "bottom", legend.key = element_blank(),
        panel.border = element_rect(fill = NA, color = "black", linewidth = 0.6)) +
  labs(x = "r\u00b2", y = "", fill = "")
dir.create("results/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("results/figures/fig4_dimension.png", p, width = 5, height = 3.8, dpi = 300)
cat("fig4 saved\n")
