# Fig. 2: where and when nutrient stress occurs

| Panel | Content | Method here |
|---|---|---|
| 2A | Mean Θ′ map (geometric mean over time; scale 0–4) | Authors' `global_geomean_figure_v5.m`, path edits only |
| 2B | Nutricline depth (3 μM nitrate; scale 30–250 m) | **Our reconstruction** from World Ocean Atlas 2023 (no code released) |
| 2C–F | Θ′ anomalies for January, April, July and October | Authors' `ANOVA_analysis.m` (one-line fix) and `ANOVA_monthly.m` (unchanged) |
| text | 59% of Θ′ variance is seasonal | Authors' `ANOVA_variance.m`, unchanged |

## Run
`run_fig2` in MATLAB from this folder, or `run_all('fig2')` from the repository root. Takes about 3–4 minutes.

**Optional:** compare with the published panels. This needs the paper PDF and Python:
```
python fig2/compare_to_published.py <paper.pdf> fig2/outputs/fig2_results.mat fig2/outputs/fig2_vs_published.png
```

## Inputs
| Panels | Needs |
|---|---|
| 2A, 2C–F | `data/thetaPrime_MODIS.mat` |
| 2B | `data/woa23_all_n00_01.nc` (skipped if missing) |

## Outputs (`outputs/`)
| File | Contents |
|---|---|
| `fig2_run_log.txt` | every step, check and deviation |
| `fig2_summary.csv` | reproduced vs published values |
| `fig2_results.mat` | the maps, for comparison |
| `step1_fig2A_fig1.png` | Fig. 2A |
| `step6_fig2CF.png` | Fig. 2C–F |
| `step8_fig2B.png` | Fig. 2B |
| `step3_monthly_S7_fig1.png` | all 12 months (fig. S7) |
| `step4_variance_fig1.png` | variance shares |

## Steps
| Step | What | Code |
|---|---|---|
| P | Θ′ preprocessing: 40.5°S–40.5°N, drop cells >25% missing, clip 0–4, fill gaps, 5-point lowess | Authors' `prepare_time_files.m` (unchanged) and `preprocess_LowLat_thetaPrime_v3_bathy.m` (path edits), run by `common/matlab/prep_theta.m` |
| 1 | Fig. 2A | Authors', path edits |
| 2 | Per-cell two-way ANOVA (year + month) | Authors', one-line fix |
| 3 | Monthly anomalies | Authors', unchanged |
| 4 | Seasonal and yearly variance shares | Authors', unchanged |
| 5 | Coordinate checks: land mask and 10 named landmarks | Ours |
| 6 | Fig. 2C–F panel on the published ±1.5 scale (the authors' script uses ±2) | Ours (plots the authors' output) |
| 7 | Checks of how 8-day composites are assigned to months and of the anomaly baseline | Ours |
| 8 | Fig. 2B from WOA23 | Ours |

## Deviations (all written to the log)
- **Missing ocean mask:** `BathyLL.mat` (shallow-water mask) is not released; an all-true mask is used.
- **Rebuilt inputs:**
  - `LAT2.mat` and `LON3.mat` are rebuilt from the Dryad coordinates.
  - `inferno_cmap.mat` is supplied from matplotlib (colours only).
  - `ddd2mmdd` is replaced by a 3-line stand-in.
- **Longitude order:** the Fig. 2A script, unlike the others, doesn't reorder longitude, so it gets its own copy of the data in the matching order. Coordinate checks confirm every map.
- **Year levels:** the ANOVA has 21 year levels because of one composite dated 1 January 2022; the paper reports 20. Step 7 shows this changes anomalies by at most 0.031.
- **Fig. 2B choices** (the paper doesn't specify):
  - annual climatology, all decades, objectively analysed mean;
  - linear interpolation between standard depths;
  - surface nitrate ≥ 3 → 0 m; never reaching 3 → blank;
  - masked to cells with Θ′ data, as in the published panel.

## Expected results (identical in the runs of 4 and 18 Nov 2026, MATLAB R2024a)
| Quantity | Ours | Published |
|---|---|---|
| Median seasonal share of variance | 0.528 | 0.59 |
| Median yearly share of variance | 0.063 | not stated |
| ANOVA grid cells | 22,468 | 20,822 |
| Median geometric-mean Θ′ (2A) | 1.672 | — |
| Land cells empty / landmarks correct (2A, 2C) | 1.000 / 10 of 10 | — |
| anovan vs independent least squares (max difference) | 4 × 10⁻¹⁴ | 0 expected |

**Agreement with the published panels** (`compare_to_published.py`, values read from the figure's colours):

| Panel | Pearson r | Cells within ±0.25 |
|---|---|---|
| 2A | 0.89 | 89.1% |
| 2C January | 0.94 | 92.4% |
| 2D April | 0.74 | 89.2% |
| 2E July | 0.92 | 89.9% |
| 2F October | 0.69 | 89.6% |

April and October score lower because their anomalies are about half as large, while the digitizing error is the same (about 0.25) in every month.

**2B (run of 18 Nov 2026):**
- Nutricline values for 20,790 of 22,468 Θ′ cells; median 101 m; 10.5% at 0 m (surface nitrate ≥ 3 μM); 1.9% deeper than 250 m.
- Land mask and landmark checks pass.
- Visually it matches the published panel: deep nutriclines in all five subtropical gyres, shallow ones along the equator and coasts. It has not yet been compared numerically.

All other values above were identical in the 18 Nov 2026 run.

## Open issues
- **Seasonal share 0.528 vs 0.59.** Restricting to the cells the paper shows gives 0.535. Other ways of summarising give 0.564 (pooled) and 0.610 (seasonal + yearly). The likely cause is a different configuration from the released code (latitude band, cell mask or input version); it's unresolved.
- **Cell set.** 1,060 cells have data here but are blank in the published maps. 74% of them are within 2 cells of land, consistent with the unreleased shallow-water mask.
