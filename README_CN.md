# 中国排污权初始有偿使用费定价——数据与分析代码

本仓库是论文 *Provincial Differences in Pricing of the Emission Rights Initial Cost Affecting the Sustainability of China's Emission Trading Policy*（Sustainability，稿件编号 4458149）的配套材料。

本页是 README 的中文版，内容与英文版 `README.md` 一致，供中文读者参考；脚本、路径与结果文件均为英文版本。

## 数据

`data/analysis_data.csv`：清洗后的分析数据集，89 条记录，覆盖 18 个省份、5 种污染物（COD、氨氮、SO2、NOx、VOCs），年份 2015 至 2026。每条记录是某省某份定价文件中的一个污染物价格，并匹配该文件年份及 11 项省级年度指标（第 7 至 17 列）。

`data/raw_data.csv`：清洗前的数据，列相同，109 条记录。模型使用 11 项指标中的 6 项，按法定三个维度每维两项：经济维度为人均 GDP、规模以上工业利润、环境污染治理投资占 GDP 比重；环境维度为排放占比、环境优良率；成本维度为治理设施占比。`code/common.R` 按列位置选取这 6 项。

数据清理（未提供代码）：从公开发布的省级文件中收集 109 条定价记录。出现次数少于三次的污染物记录共 9 条（铅、砷、铬、镉、汞各 1 条，总磷、颗粒物各 2 条）因统计信息不足剔除；省份、污染物、年份、价格四项完全相同的重复记录 11 条剔除；最终保留 89 条。

## 仓库结构

| 路径 | 说明 |
|------|------|
| `run_all.R` | 按顺序执行全部脚本。在本目录下运行 `Rscript run_all.R`。 |
| `code/common.R` | 共用函数：数据读取、固定的 10×5 外层折划分（种子为 `rep*100+42`）、内层三折调参辅助函数，以及全文使用的 R² 指标（观测值与预测值的平方皮尔逊相关）。 |
| `code/01_data_descriptives/` | 表 1（描述统计）；两因素方差分解（省份与污染物的净贡献，61% 与 16%，合计 78%）；留一省份均值与留一污染物中位数两个参照基线。 |
| `code/02_model_comparison/` | 表 3：五个候选模型（弹性网、偏最小二乘、K 近邻、随机森林、SVR-RBF）在同等调参下各一个脚本，另含核函数比较，以及运行超参数选取与嵌套交叉验证校核。 |
| `code/03_validation/` | 表 4：四种验证设计（随机 10×5 折交叉验证、留一省份、省 bootstrap、留一污染物）各一个脚本，各自把折外预测写入 `results/predictions/`。 |
| `code/04_correlation_diagnostics/` | 11 项候选指标与价格的相关性（表 5 与图 6）；子集敏感性与置换重要性（图 3）。 |
| `code/05_figures/` | 每个图面板一个脚本，读取 `results/` 并写入 `results/figures/`。与论文图号的对应关系：fig1 分布 → 图 1(a)，fig2 价格趋势 → 图 1(b)，fig3 折外散点 → 图 2，fig4 维度子集 R² → 图 3(a)，fig5 置换重要性 → 图 3(b)，fig6 验证对比 → 图 4，fig7 留一省份散点 → 图 5，fig8 相关性森林图 → 图 6。 |
| `results/` | 全部输出：结果表（CSV）、图（PNG）与折外预测。 |
| `session_info.txt` | 所用的 R 版本与各包版本。 |

## 分析约定（适用于全部脚本）

- **R² 定义**：观测价格与预测价格的平方皮尔逊相关。
- **外层折**：所有模型与验证脚本使用同一套 10×5 折划分（种子 `rep*100+42`），因此各结果可直接比较，配对检验成立。
- **同等调参**：在每一个外层折中，各模型的超参数只在外层训练部分上选取，通过该模型网格的内层三折交叉验证完成；外层测试折始终不参与。各网格列于论文表 3。
- **运行超参数**：C = 10，γ = 0.20，ε = 0.05，由全样本上的网格搜索选出（5×5 交叉验证下的最优格）。变量在每个训练折上做 z 分数标准化，标准化参数沿用到测试折。

## 执行顺序与关键数值

| 脚本 | 对应论文输出 | 关键数值 |
|--------|-------------------|-------------|
| `01_data_descriptives/descriptives.R` | 表 1 | 合计 R² = 78%；净贡献 61%（省份）与 16%（污染物）；留一省份均值基线 R² = 0.44；留一污染物中位数基线约 0.08 |
| `02_model_comparison/model_*.R` | 表 3 | 逐折 R²：SVR 0.54 > 随机森林 0.46 > KNN 0.23 > PLS −0.09 > 弹性网 −0.07 |
| `02_model_comparison/kernel_comparison.R` | 表 3 | RBF 0.54 > 线性 −0.14 > 多项式 −1.28 > sigmoid −6933 |
| `02_model_comparison/hyperparameters.R` | 3.3 节 | 全样本网格选取：最优格为 (10, 0.20, 0.05)；嵌套校核 R² 0.54 对固定参数 0.60 |
| `03_validation/validation_random_cv.R` | 4.1 节 | R² = 0.69，RMSE = 1364；绝对偏差中位数 540，47.2% 的记录误差在 500 元以内 |
| `03_validation/validation_lopo.R` | 4.2 节 | R² = 0.035，RMSE = 2907；留一省份下随机森林 0.012、KNN 0.056；省分类器（袋外）准确率 100%；对数变换稳健性 R² = 0.004 |
| `03_validation/validation_bootstrap.R` | 4.2 节 | 中位数 0.066，90 分位 0.275 |
| `03_validation/validation_lopo_pollutant.R` | 4.2 节 | 总体 R² = 0.66 |
| `03_validation/cleaning_specs_robustness.R` | 稳健性检验 | 留一省份 R² = 0.003（全量 109）／0.000（去重后）／0.039（出现次数不少于三次）／0.035（分析集） |
| `03_validation/supplementary_checks.R` | 补充核验 | 常规 R² 0.696／−0.405／−0.375／0.644；bootstrap 的 RMSE 2,852，留一污染物 1,464 |
| `03_validation/positive_control.R` | 正控制模拟 | 留一省份可恢复 R² = 0.43（规则解释 74% 方差）／0.17（解释 50%），真实数据为 0.035 |
| `04_correlation_diagnostics/correlation.R` | 表 5／图 6 | 少数记录层面的相关达到名义显著；22 次检验无一通过 Bonferroni 校正 |
| `04_correlation_diagnostics/sensitivity_importance.R` | 4.1 节／图 3 | 子集 0.70／0.34／0.14／0.15；置换重要性下降 0.37／0.27／0.15／0.09／0.12／0.24 |
| `04_correlation_diagnostics/importance_lopo.R` | 4.1 节／图 3 | 留一省份下子集 0.035／0.019／0.044／0.003；置换下降约等于 0（人均 GDP 由 0.37 降至 0） |

## 复现说明

省 bootstrap 与随机 10×5 折交叉验证含随机性；种子固定在 `common.R`（外层折）与各脚本内部（bootstrap 为种子 42），因此重新运行可复现报告中的数值。逐特征置换重要性同样依赖随机置换，未设种子，重新运行时特征排序一致，但个别数值会有几百分之一的出入。其余设计（留一省份、留一污染物）为确定性计算。

需要的 R 包：`e1071`、`randomForest`、`caret`、`glmnet`、`pls`、`ggplot2`、`gridExtra`。
