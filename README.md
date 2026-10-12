# ERIC Pricing in China - Data and Analysis Code

Accompanying the manuscript *"Provincial Differences in Pricing of the Emission Rights Initial Cost Affecting the Sustainability of China's Emission Trading Policy"* (Sustainability, manuscript ID 4458149).

## Data

`data/analysis_data.csv` — the cleaned analysis dataset of 89 records across 18 provinces and 5 pollutants (COD, NH3-N, SO2, NOx, VOCs), 2015–2026. Each record is one pollutant price from one provincial pricing document, matched to the document year and to 11 province-year indicators (columns 7–17).

`data/raw_data.csv` — the same columns before cleaning, 109 records. The models use six of the eleven indicators, two per statutory dimension: per capita GDP, industrial profits and treatment investment as a share of GDP (economic), emission share and environmental quality rate (environmental), and treatment facility share (cost). `code/common.R` selects them by position.

Data cleaning (no code provided): 109 pricing records were collected from publicly released provincial documents. Nine records of pollutants observed fewer than three times (lead, arsenic, chromium, cadmium, mercury, total phosphorus, particulate matter) were excluded for insufficient statistical information, and 11 exact duplicates (identical province, pollutant, year, and price) were removed, leaving 89 records.

## Repository structure

| Path | Purpose |
|------|---------|
| `run_all.R` | Executes every script in order. Run `Rscript run_all.R` from this directory. |
| `code/common.R` | Shared functions: data loading, the fixed 10×5 outer fold partition (seeds `rep*100+42`), the inner 3-fold tuning helper, and the R² metric (squared Pearson correlation) used throughout. |
| `code/01_data_descriptives/` | Table 1 (descriptive statistics); two-factor variance decomposition (net contributions of province and pollutant, 61% and 16%, joint 78%); leave-one-out province-mean and pollutant-median baselines. |
| `code/02_model_comparison/` | Table 3: one script per candidate model (elastic net, PLS, KNN, random forest, SVR-RBF) under equal tuning, the kernel comparison, and the operating-hyperparameter selection with the nested-CV check. |
| `code/03_validation/` | Table 4: one script per validation design (random 10×5-fold CV, leave-one-province-out, province bootstrap, leave-one-pollutant-out), each writing its out-of-fold predictions to `results/predictions/`. |
| `code/04_correlation_diagnostics/` | Correlations of the 11 candidate indicators with price (Table 5 / Figure 6); subset sensitivity and permutation importance (Figure 3). |
| `code/05_figures/` | One script per figure panel, each reading `results/` and writing to `results/figures/`. Mapping to manuscript figures: fig1 distribution → Figure 1(a), fig2 pricing trends → Figure 1(b), fig3 OOF scatter → Figure 2, fig4 dimension subset R² → Figure 3(a), fig5 permutation importance → Figure 3(b), fig6 validation comparison → Figure 4, fig7 LOPO scatter → Figure 5, fig8 correlation forest → Figure 6. |
| `results/` | All outputs: tables (CSV), figures (PNG), and out-of-fold predictions. |
| `session_info.txt` | R version and package versions used. |

## Analysis protocol (all scripts)

- **R² definition**: squared Pearson correlation between observed and predicted prices.
- **Outer folds**: identical 10×5 fold partition for every model and validation script (seeds `rep*100+42`), so all results are directly comparable and paired tests are valid.
- **Equal tuning**: in each outer fold, each model's hyperparameters are selected on the outer training part only, by inner 3-fold cross-validation over the model's grid; the outer test fold is never touched. Grids are listed in Table 3 of the manuscript.
- **Operating hyperparameters**: C = 10, γ = 0.20, ε = 0.05, selected by grid search over the full dataset (the best cell under 5×5 CV). Variables are z-score standardized on each training fold with parameters transferred to the test fold.

## Execution order and expected headline numbers

| Script | Manuscript output | Key numbers |
|--------|-------------------|-------------|
| `01_data_descriptives/descriptives.R` | Table 1 | joint R² = 78%; net contributions 61% (province) / 16% (pollutant); province-mean baseline (leave-one-out) R² = 0.44; pollutant-median baseline ≈ 0.08 |
| `02_model_comparison/model_*.R` | Table 3 | per-fold R²: SVR 0.54 > RF 0.46 > KNN 0.23 > PLS −0.09 > EN −0.07 |
| `02_model_comparison/kernel_comparison.R` | Table 3 | RBF 0.54 > linear −0.14 > polynomial −1.28 > sigmoid −6933 |
| `02_model_comparison/hyperparameters.R` | Section 3.3 | selection with r² on the full dataset: best cell (10, 0.20, 0.05); nested check R² 0.54 vs fixed 0.60 |
| `03_validation/validation_random_cv.R` | Section 4.1 | R² = 0.69, RMSE = 1364; median abs dev 540, 47.2% within 500 CNY |
| `03_validation/validation_lopo.R` | Section 4.2 | R² = 0.035, RMSE = 2907; RF 0.012, KNN 0.056 under LOPO; province classifier accuracy (out-of-bag) 100%; log-transform robustness R² = 0.004 |
| `03_validation/validation_bootstrap.R` | Section 4.2 | median 0.066, Q90 0.275 |
| `03_validation/validation_lopo_pollutant.R` | Section 4.2 | overall R² = 0.66 |
| `03_validation/cleaning_specs_robustness.R` | robustness (R1-C1 / R2-C8) | LOPO R² = 0.003 (full 109) / 0.000 (deduplicated) / 0.039 (N ≥ 3) / 0.035 (analysis set) |
| `03_validation/round2_checks.R` | round-2 reviewer requests | conventional R² 0.696 / −0.405 / −0.375 / 0.644; RMSE bootstrap 2,852, LOPO-pollutant 1,464 |
| `03_validation/positive_control.R` | round-2 positive control | LOPO recovers R² = 0.43 (rule 74%) / 0.17 (rule 50%) vs 0.035 on real data |
| `04_correlation_diagnostics/correlation.R` | Table 5 / Figure 6 | a few record-level correlations reach nominal significance; none survives Bonferroni for the 22 tests |
| `04_correlation_diagnostics/sensitivity_importance.R` | Section 4.1 / Figure 3 | subsets 0.70/0.34/0.14/0.15; importance drops 0.37/0.27/0.15/0.09/0.12/0.24 |
| `04_correlation_diagnostics/importance_lopo.R` | Section 4.1 / Figure 3 (round 2) | LOPO subsets 0.035/0.019/0.044/0.003; LOPO drops ≈ 0 (per capita GDP 0.37 → 0) |

## Reproducibility

The province bootstrap and the random 10×5-fold cross-validation are stochastic; seeds are fixed within `common.R` (outer folds) and inside each script (bootstrap: seed 42), so a fresh run reproduces the reported numbers. The per-feature permutation importance also draws random permutations; it is not seeded, so a fresh run reproduces the ordering of the features but individual drops may differ by a few hundredths. The remaining designs (leave-one-province-out, leave-one-pollutant-out) are deterministic.

R packages required: `e1071`, `randomForest`, `caret`, `glmnet`, `pls`, `ggplot2`, `gridExtra`.
