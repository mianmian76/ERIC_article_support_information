# ============================================================================
# fig7_lopo.R — Figure 7: predicted vs actual prices under leave-one-province-
# out cross-validation (reads results/predictions/lopo.csv)
# ============================================================================
suppressMessages(library(ggplot2))
source("code/05_figures/fig_labels.R")
pr <- read.csv("results/predictions/lopo.csv")
prov_en <- c(甘肃 = "Gansu", 海南 = "Hainan", 福建 = "Fujian", 安徽 = "Anhui",
             浙江 = "Zhejiang", 湖南 = "Hunan", 江西 = "Jiangxi", 湖北 = "Hubei",
             陕西 = "Shaanxi", 内蒙古 = "Inner Mongolia", 重庆 = "Chongqing",
             山东 = "Shandong", 广东 = "Guangdong", 宁夏 = "Ningxia",
             江苏 = "Jiangsu", 河南 = "Henan", 河北 = "Hebei", 上海 = "Shanghai")
df <- data.frame(Actual = pr$Actual, Predicted = pr$Predicted,
                 Province = unname(prov_en[trimws(pr$Province)]))
p <- ggplot(df, aes(Actual, Predicted, color = Province)) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  annotate("text", x = max(df$Actual) * 0.9, y = min(df$Predicted) + 500,
           label = "R² = −0.405\nRMSE = 2907", size = 4, hjust = 1) +
  # Thousands separators only from five digits up; true minus sign on the axis
  scale_x_continuous(labels = comma_5plus) +
  scale_y_continuous(labels = comma_5plus) +
  coord_cartesian(xlim = c(0, max(df$Actual)), ylim = c(min(df$Predicted), max(df$Actual)), expand = FALSE) +
  theme_classic(base_size = 11) +
  theme(panel.grid = element_blank(),
        panel.border = element_rect(fill = NA, color = "black", linewidth = 1)) +
  labs(x = "Actual price (CNY/(ton·yr))", y = "Predicted price (CNY/(ton·yr))")
dir.create("results/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("results/figures/fig7_lopo.png", p, width = 7.5, height = 6.5, dpi = 300)
cat("fig5 saved\n")
