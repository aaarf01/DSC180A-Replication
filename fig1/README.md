# Fig. 1: satellite Θ′ vs field measurements

| Panel | Content | Published | Method here |
|---|---|---|---|
| 1A | Θ′ vs nutricline depth (density plot with binned means) | R = −0.52, P < 10⁻²⁰⁰ | **Our reconstruction** (no code released) |
| 1B | Random forest R²: nutricline alone vs nutricline + Ω biomarkers | bars ~0.36 and ~0.62 | Authors' R script, **unchanged** |
| 1C | Θ′ by dominant nutrient-stress type | six bars (approx. N High −0.13, N Med +0.32, P High +0.20, P Med +0.15, Fe High −0.12, Fe Med −0.27) | **Our reconstruction** (no code released) |
| 1D | Θ′ vs nitrogen-use gene traits | box plots | **Not reproducible:** needs per-gene trait abundances (table S1) that are not in the released data |

## Run
- **Everything:** `run_fig1` in MATLAB from this folder, or `run_all('fig1')` from the repository root. MATLAB calls R for 1B and 1C.
- **R parts only:** from a terminal, `Rscript fig1/fig1b.R` and `Rscript fig1/fig1c.R`.
- **Optional Python check of 1B:** `python fig1/independent_rf_check.py .` from the repository root.

## Inputs
| Panel | Needs |
|---|---|
| 1B, 1C | `data/data_insitu_v2_25-04.csv` and `data/sat_data_25-04/` (included), plus R with `randomForest`, `reshape`, `ggplot2`, `pdp` |
| 1A | `data/thetaPrime_MODIS.mat` and `data/woa23_all_n00_01.nc` |

## Outputs (`outputs/`)
| File | Contents |
|---|---|
| `fig1b_run_log.txt` | sample counts, both R² values, the 6 × 15 matchup grid, software versions |
| `fig1b_results.csv` | the key 1B numbers |
| `fig1b_plots.pdf` | the authors' matchup heatmap and bar chart |
| `fig1c_run_log.txt`, `fig1c_results.csv` | the four candidate definitions vs the published bars |
| `fig1c_bars.pdf` | our bars next to the published values |
| `fig1_run_log.txt` | the MATLAB log, including 1A |
| `fig1a_results.csv` | R and P for each 1A version |
| `fig1a_reconstruction.png` | the 1A density plot |

## Methods and choices
- **1B:**
  - The authors' `random_forest_analysis_v2.R` is sourced exactly as released (checksum verified).
  - It fits a random forest to every combination of 6 spatial × 15 time matchup windows, picks 2° × 2° and ±20 days, and compares a nutricline-only model with nutricline + five Ω biomarkers.
  - R² is out-of-bag.
- **1C:**
  - **Definition.** Each sample is classified by its dominant stress type: the largest of the six Ω biomarkers. The bar is the mean Θ′ left over after the authors' nutricline-only random forest.
  - **Residuals.** The authors' script computes these residuals but never uses them; we source it unchanged, so the residuals are exactly theirs.
  - **Why this definition.** It was chosen from four candidates tested in a Python prototype (6/6 signs, r = 0.98 with the published bars). All four are reported.
- **1A:**
  - **Grid-level comparison.** The field-sample version gives R = −0.43 with P ≈ 10⁻⁵⁰ (n = 1,091), which cannot produce the published P < 10⁻²⁰⁰. So the panel must compare grid cells: satellite Θ′ against a nutricline map, the depth of 3 μM nitrate in World Ocean Atlas 2023.
  - **Three versions reported:** geometric-mean Θ′, arithmetic-mean Θ′, and every 8-day value.
  - **Nutricline map:** built the same way as the Fig. 2B reconstruction, from the same shared function in `common/`.

## Expected results (run of 18 Nov 2026: MATLAB R2024a, R 4.4.1, randomForest 4.7-1.2)
| Panel | Quantity | Ours | Published |
|---|---|---|---|
| 1A | R, every 8-day Θ′ value vs nutricline (V3, n = 18,648,630) | −0.513 | −0.52 |
| 1A | R, geometric-mean Θ′ per cell vs nutricline (V1, n = 20,790) | −0.660 | — |
| 1A | R, arithmetic-mean Θ′ per cell (V2) | −0.644 | — |
| 1A | Binned means (V1) vs published red line, correlation over 10 bins | 1.00 | — |
| 1B | Samples in final models | 1,091 | 990 |
| 1B | OOB R², nutricline only | 0.3421 | ~0.36 |
| 1B | OOB R², nutricline + biomarkers | 0.6051 | ~0.62 |
| 1B | Python cross-check (scikit-learn, 20 seeds) | 0.342 / 0.584 | — |
| 1C | Main definition: sign agreement / r with published bars | 6/6 / 0.95 | — |
| 1C | Other candidates (partial dependence; Ω > 0; raw by type) | 3/6, 5/6, 3/6 | — |

**1C bars** (ours vs published, read from the figure):

| Stress type | Ours | Published |
|---|---|---|
| N High | −0.16 | −0.13 |
| N Med | +0.39 | +0.32 |
| P High | +0.15 | +0.20 |
| P Med | +0.06 | +0.15 |
| Fe High | −0.19 | −0.12 |
| Fe Med | −0.18 | −0.27 |

**1A interpretation.** The published R (−0.52) matches the version using every 8-day value. The published red line matches the per-cell means (V1, values within about 0.1). Most likely the authors plotted all 8-day values and drew the line through cell means.

## Known issues
- **Wrong file in the matchup grid:** the authors' script loads the 1° file into the "single pixel" slot, so the `_1p` file never enters the analysis. This affects only the first column of the matchup grid, not 1B. It is left as released.
- **Sample count:** 1,091 samples have satellite matches; the paper reports 990. No filtering was applied to match the paper.
