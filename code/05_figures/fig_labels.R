# ============================================================================
# fig_labels.R — shared axis-label helpers for the figures.
#
# House rule for the manuscript (copy-editing query): a comma separates thousands
# only from five digits upwards; four-digit values stay without a comma.
# Negative numbers carry a true minus sign (U+2212), not a hyphen.
# ============================================================================

# 1000 -> "1000", 2500 -> "2500", 10000 -> "10,000", -500 -> "\u2212500"
comma_5plus <- function(v) {
  v <- round(as.numeric(v))
  out <- format(v, trim = TRUE, scientific = FALSE)
  need <- is.finite(v) & abs(v) >= 10000
  out[need] <- sub("^(-?)([0-9]+)([0-9]{3})$", "\\1\\2,\\3", out[need])
  sub("^-", "\u2212", out)
}

# 0.696 -> "0.696", -0.405 -> "\u22120.405"
num_label <- function(v, digits = 3) {
  sub("^-", "\u2212", formatC(v, format = "f", digits = digits))
}
