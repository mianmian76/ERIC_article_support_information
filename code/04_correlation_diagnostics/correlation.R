# ============================================================================
# correlation.R — Correlations of the 11 candidate indicators with price
#
# Outputs results/tables/correlations.csv (Table 5 / Figure 6):
# pooled correlations over all 89 records and between-province correlations
# over the 18 province means, with two-tailed p-values.
# ============================================================================
source("code/common.R")

indicators <- d[, 7:17]
en_labels <- c("Per capita GDP", "Population", "GDP", "Industrial PPI",
               "Per capita income", "Emission share", "Industrial assets",
               "Industrial profits", "Treatment inv./GDP", "Environmental quality",
               "Treatment facility share")
pval <- function(r, m) 2 * pt(-abs(r) * sqrt((m - 2) / (1 - r^2)), df = m - 2)

rows <- list()
for (i in 1:11) {
  x <- as.numeric(indicators[[i]])
  rp <- cor(x, Y)
  rb <- cor(tapply(x, prov, mean), tapply(Y, prov, mean))
  rows[[i]] <- data.frame(
    Indicator_CN = colnames(indicators)[i],
    Indicator_EN = en_labels[i],
    Pooled_r = rp, Pooled_r2 = rp^2, Pooled_p = pval(rp, n),
    Between_r = rb, Between_r2 = rb^2, Between_p = pval(rb, length(unique(prov))))
}
out <- do.call(rbind, rows)
dir.create("results/tables", showWarnings = FALSE, recursive = TRUE)
write.csv(out, "results/tables/correlations.csv", row.names = FALSE)
print(out[, c("Indicator_EN", "Pooled_r", "Pooled_r2", "Pooled_p",
              "Between_r", "Between_r2", "Between_p")], digits = 3)
