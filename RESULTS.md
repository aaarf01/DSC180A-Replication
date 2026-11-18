# Replication results

**Run:** 18 Nov 2026, with `run_all` in this repository. MATLAB R2024a (Statistics and Machine Learning 24.1, Curve Fitting 24.1), R 4.4.1 (randomForest 4.7-1.2), macOS. Total run time about 10 minutes.

**How to read the "How" column:**
- **Authors' code:** their released scripts, checksum-verified, with only the edits listed in each figure README.
- **Reconstruction:** our own implementation from the paper's text and captions, because no code was released.
- **Digitized comparison:** values read from the colours of the published figure. These comparisons carry reading error of roughly ±0.1–0.25 depending on the panel.

## Overall

| Figure | Panel | How | Verdict |
|---|---|---|---|
| 1 | A: Θ′ vs nutricline | Reconstruction | **Reproduced** |
| 1 | B: random forest R² | Authors' code | **Reproduced** |
| 1 | C: Θ′ by stress type | Reconstruction | **Reproduced** |
| 1 | D: Θ′ vs gene traits | — | Not reproducible: data not released |
| 2 | A: mean Θ′ map | Authors' code | **Reproduced** |
| 2 | B: nutricline map | Reconstruction | **Reproduced (visual)** |
| 2 | C–F: monthly anomalies | Authors' code | **Reproduced** |
| 2 | text: 59% of variance seasonal | Authors' code | **Not matched** (0.528) |
| 3 | A, D: climate-index correlations | Authors' code | **Reproduced** |
| 3 | B, C: 2011 and 2015 maps | Authors' code | **Reproduced** |
| 3 | E, F: PDO-phase maps | Reconstruction | **Reproduced** |
| 4 | A–C: trends | Authors' code (histograms ours) | **Reproduced** (Θ′ median slightly smaller) |
| 4 | D: regional trends | Authors' code + corrected version | Blocked: input table not released |

## Key numbers

| Panel | Quantity | Ours | Published |
|---|---|---|---|
| 1A | R, every 8-day Θ′ value vs WOA23 nutricline (n = 18.6 million) | **−0.513** | −0.52 |
| 1A | R, per-cell geometric-mean Θ′ vs nutricline (n = 20,790) | −0.660 | — |
| 1A | Binned-mean line vs the published red line (correlation of 10 bins) | 1.00 | — |
| 1B | OOB R², nutricline only | **0.342** | ~0.36 (bar) |
| 1B | OOB R², nutricline + biomarkers | **0.605** | ~0.62 (bar) |
| 1B | Samples in final models | 1,091 | 990 |
| 1C | Signs matching the 6 published bars | **6/6** | — |
| 1C | Correlation with the published bar heights | **0.95** | — |
| 2 | Median seasonal share of Θ′ variance | 0.528 | **0.59** |
| 2 | Grid cells | 22,468 | 20,822 |
| 2B | Median nutricline depth over Θ′ cells | 101 m | (colour scale 30–250 m) |
| 3A | \|R\|, PC5 vs ONI (P) | **0.837** (10⁻²³⁶) | 0.81 (< 10⁻²¹⁶) |
| 3D | \|R\|, PC6 vs PDO (P) | **0.609** (10⁻⁹²) | 0.59 (< 10⁻⁸⁵) |
| 3A, 3D | Modes most correlated with ONI / PDO | PC5 / PC6 | PC5 / PC6 |
| 3A, 3D | Same, with the 20-point smoothing the methods text states (the code uses 30) | 0.824 / 0.572 | 0.81 / 0.59 |
| 4 | Median Θ′ trend (/yr) | −1.23 × 10⁻³ | −1.3 × 10⁻³ |
| 4 | Median SST trend (°C/yr) | **2.34 × 10⁻²** | 2.3 × 10⁻² |
| 4 | Area fraction with SST increase | **0.887** | 0.89 |
| 4 | Average SST rise over the record (°C) | **0.431** | 0.43 |

## Agreement with the published maps (digitized comparison)

| Panel | Spearman | Pearson | Cells within tolerance |
|---|---|---|---|
| 2A mean Θ′ | 0.96 | 0.89 | 89% within ±0.25 |
| 2C January | 0.96 | 0.94 | 92% within ±0.25 |
| 2D April | 0.82 | 0.74 | 89% within ±0.25 |
| 2E July | 0.94 | 0.92 | 90% within ±0.25 |
| 2F October | 0.78 | 0.69 | 90% within ±0.25 |
| 3B 2011 | 0.83 | 0.73 | 81% within ±0.1 |
| 3C 2015 | 0.82 | 0.83 | 81% within ±0.1 |
| 3E PDO cool (reconstruction) | 0.81 | 0.63 | 98% within ±0.1 |
| 3F PDO warm (reconstruction) | 0.86 | 0.45 | 98% within ±0.1 |

**Why some Pearson values are low.** Lower Pearson values (2D, 2F, 3E, 3F) come from panels with small anomalies. Their colours sit near the white middle of the colour bar, where reading error matters most, so Spearman and the within-tolerance share are the better measures there. The land-mask agreement with the published maps is 94–95% in every panel.

## Unresolved differences and what probably explains them

| Difference | Likely explanation |
|---|---|
| Seasonal share 0.528 vs 0.59 | Not explained by the cell mask (0.535 on the paper's visible cells). Probably a different configuration (latitude band, time span or input version) from the released code |
| Grid cells 22,468 vs 20,822 | Unreleased shallow-water mask (`BathyLL.mat`). 74% of the 1,060 cells blank in the paper but present here lie within 2 cells of land |
| Median Θ′ trend −1.23 vs −1.3 × 10⁻³ | Same cell-mask or input-version differences |
| Fig. 1B n = 1,091 vs 990 | Not explained by the released data or code |
| Fig. 1A: which comparison was plotted | The R matches all 8-day values (−0.513); the red line matches the per-cell means. Most likely the authors plotted all values and drew the line through the cell means |
| Fig. 3 \|R\| slightly higher (0.84 vs 0.81; 0.61 vs 0.59) | Index versions (NOAA revises ONI and PDO), the newer Climate Data Toolbox, and the smoothing window |

## Problems found in the released code

Details are in the figure READMEs.

1. **Longitude order.** The released scripts disagree on longitude order, which puts maps 200° off when they're run together. This is handled and checked in every figure.
2. **`ANOVA_analysis.m`.** It can't run as released: the coefficient array is preallocated too small.
3. **`ANOVA_yearly.m`.** It fails with the 21 year levels in the released data (one composite is dated 2022).
4. **Fig. 1B matchup grid.** It loads the 1° file in place of the single-pixel file.
5. **Fig. 4D script.** It assigns the wrong longitude to 99.7% of grid cells.
6. **Missing helper files.** `BathyLL.mat`, `LAT2.mat`, `LON3.mat`, `inferno_cmap.mat` and `ddd2mmdd` are referenced but not released.
7. **Methods vs code.** The smoothing window differs between the methods (20) and the code (30).
