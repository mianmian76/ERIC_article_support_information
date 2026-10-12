# ============================================================================
# run_all.R — Execute every analysis and figure script in order.
#
# Usage:
#   Rscript run_all.R            (from this directory)
#   or source("run_all.R") in RStudio after setting the working directory here.
# ============================================================================
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("--file=", "", args[grep("--file=", args)])
root <- if (length(file_arg)) dirname(normalizePath(file_arg)) else getwd()
setwd(root)
cat("Repository root:", getwd(), "\n")

# Fresh outputs on every run (prevents duplicate rows on re-runs)
unlink("results", recursive = TRUE)

scripts <- c(
  "code/common.R",
  "code/01_data_descriptives/descriptives.R",
  "code/02_model_comparison/model_elasticnet.R",
  "code/02_model_comparison/model_pls.R",
  "code/02_model_comparison/model_knn.R",
  "code/02_model_comparison/model_rf.R",
  "code/02_model_comparison/model_svr.R",
  "code/02_model_comparison/paired_svr_rf.R",
  "code/02_model_comparison/kernel_comparison.R",
  "code/02_model_comparison/hyperparameters.R",
  "code/03_validation/validation_random_cv.R",
  "code/03_validation/validation_lopo.R",
  "code/03_validation/validation_bootstrap.R",
  "code/03_validation/validation_lopo_pollutant.R",
  "code/03_validation/cleaning_specs_robustness.R",
  "code/03_validation/supplementary_checks.R",
  "code/03_validation/positive_control.R",
  "code/04_correlation_diagnostics/correlation.R",
  "code/04_correlation_diagnostics/sensitivity_importance.R",
  "code/04_correlation_diagnostics/importance_lopo.R",
  "code/05_figures/fig1_distribution.R",
  "code/05_figures/fig2_trend.R",
  "code/05_figures/fig3_oof.R",
  "code/05_figures/fig4_dimension.R",
  "code/05_figures/fig5_importance.R",
  "code/05_figures/fig6_validation.R",
  "code/05_figures/fig7_lopo.R",
  "code/05_figures/fig8_forest.R"
)
for (s in scripts) {
  cat("\n=====", s, "=====\n")
  source(s)
}
cat("\n=== ALL DONE ===\n")
