# ============================================================================
# fig2_trend.R — Figure 2: pricing trends by pollutant over time
# Four conventional pollutants (COD, NH3-N, SO2, NOx), raw points with loess
# smooth and confidence band, faceted 2 x 2 with free y scales.
# (Style follows the original submission version; Set1 palette.)
# ============================================================================
suppressMessages(library(ggplot2))
source("code/05_figures/fig_labels.R")
source("code/common.R")

pol_en <- c(COD = "COD", `氨氮` = "NH3-N", SO2 = "SO2", NOX = "NOx")
df <- data.frame(Pollutant = pol_en[pol],
                 Price = Y, Year = as.numeric(yr))
df <- df[!is.na(df$Pollutant), ]
df$Pollutant <- factor(df$Pollutant, levels = c("COD", "NH3-N", "SO2", "NOx"))

p <- ggplot(df, aes(Year, Price, color = Pollutant)) +
  geom_point(alpha = 0.4, size = 1.5) +
  geom_smooth(method = "loess", se = FALSE, span = 0.8) +
  facet_wrap(~ Pollutant, scales = "free_y", nrow = 2) +
  scale_x_continuous(breaks = seq(2015, 2026, 2)) +
  scale_y_continuous(limits = c(0, NA), labels = comma_5plus) +
  scale_color_brewer(palette = "Set1") +
  theme_classic(base_size = 11) +
  theme(panel.grid = element_blank(),
        panel.border = element_rect(fill = NA, color = "black", linewidth = 0.6),
        strip.background = element_blank(),
        legend.position = "none") +
  labs(x = "Year", y = "Price (CNY/(ton·yr))")
dir.create("results/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("results/figures/fig2_trend.png", p, width = 9, height = 5.5, dpi = 300)
cat("fig2 saved\n")
