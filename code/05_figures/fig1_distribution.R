# ============================================================================
# fig1_distribution.R — Figure 1: distribution of ERIC prices by pollutant
# (boxplot with mean and outlier annotations)
# ============================================================================
suppressMessages(library(ggplot2))
source("code/05_figures/fig_labels.R")
source("code/common.R")

pol_en <- c(COD = "COD", `氨氮` = "NH3-N", SO2 = "SO2", NOX = "NOx", VOCs = "VOCs")
df <- data.frame(Pollutant = factor(pol_en[pol], levels = c("COD", "NH3-N", "SO2", "NOx", "VOCs")),
                 Price = Y)

mean_df <- aggregate(Price ~ Pollutant, df, mean)
out_df <- do.call(rbind, lapply(split(df, df$Pollutant), function(d) {
  q <- quantile(d$Price, c(0.25, 0.75)); iqr <- q[2] - q[1]
  d[d$Price > q[2] + 1.5 * iqr | d$Price < q[1] - 1.5 * iqr, , drop = FALSE]
}))

p <- ggplot(df, aes(Pollutant, Price)) +
  geom_boxplot(fill = "steelblue", color = "black", alpha = 0.6,
               outlier.shape = NA) +
  geom_point(data = mean_df, aes(color = "Mean", shape = "Mean"),
             fill = "#E74C3C", size = 2.2) +
  geom_point(data = out_df, aes(color = "Outlier"), shape = 19, size = 1.8) +
  scale_color_manual(name = "",
                     breaks = c("Mean", "Outlier"),
                     values = c("Mean" = "#E74C3C", "Outlier" = "black")) +
  scale_shape_manual(name = "", values = c("Mean" = 23)) +
  guides(shape = "none",
         color = guide_legend(override.aes = list(
           shape = c(23, 19),
           fill = c("#E74C3C", NA)))) +
  theme_classic(base_size = 11) +
  theme(panel.grid = element_blank(),
        panel.border = element_rect(fill = NA, color = "black", linewidth = 0.6),
        legend.position = c(0.92, 0.92),
        legend.justification = c(1, 1),
        legend.key = element_blank(),
        legend.background = element_blank()) +
  scale_y_continuous(labels = comma_5plus,
                     limits = c(0, 11500),
                     breaks = seq(0, 9000, 3000)) +
  labs(x = "", y = "Price (CNY/(ton·yr))")
dir.create("results/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("results/figures/fig1_distribution.png", p, width = 8, height = 4.5, dpi = 300)
cat("fig1 saved\n")
