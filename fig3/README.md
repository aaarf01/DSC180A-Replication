# Fig. 3: nutrient stress and climate cycles

| Panel | Content | Published | Method here |
|---|---|---|---|
| 3A | EOF mode 5 (PC5) vs Oceanic Niño Index (ONI) | R = 0.81, P < 10⁻²¹⁶ | Authors' `EOF_variance.m` and `climate_index_comparison.m`, unchanged |
| 3B, 3C | Θ′ anomaly maps for 2011 (La Niña) and 2015 (El Niño) | maps, ±0.8 scale | Authors' `ANOVA_yearly.m`, unchanged |
| 3D | PC6 vs Pacific Decadal Oscillation (PDO) | R = 0.59, P < 10⁻⁸⁵ | Authors', unchanged |
| 3E, 3F | Mean anomaly in PDO cool years (2007–14, 2020–21) and warm years (2002–06, 2015–19) | maps | **Our reconstruction** (no code released; years from the caption) |

## Run
`run_fig3` in MATLAB from this folder, or `run_all('fig3')` from the repository root. Takes about 5–10 minutes.

## Inputs
- `data/thetaPrime_MODIS.mat`
- `data/oni.ascii.txt` (NOAA CPC)
- `data/ersst.v5.pdo.dat` (NOAA NCEI)

Download links are in `data/README.md`.

## Outputs (`outputs/`)
| File | Contents |
|---|---|
| `fig3_run_log.txt` | every step, check and deviation |
| `fig3_summary.csv` | reproduced vs published values |
| `fig3_results.mat` | maps, principal components, correlations |
| `step7_fig3_AD.png` | panels A and D |
| `step7_fig3_maps.png` | panels B, C, E, F |
| `step2_yearly_S14_fig1.png` | all 20 yearly maps (fig. S14) |
| `step3_EOF_fig*.png`, `step5_index_comparison_fig*.png` | the authors' own figures |

## Steps
| Step | What | Code |
|---|---|---|
| P | Θ′ preprocessing (identical to Fig. 2) | Shared, `common/` |
| Y | 20 year levels: the single 1 Jan 2022 composite is counted as 2021, as in the paper (`ANOVA_yearly.m` can't run with 21) | Ours |
| 1 | Per-cell ANOVA | Authors', one-line fix |
| 2 | Yearly anomaly maps | Authors', unchanged |
| 3 | EOFs of detrended Θ′ | Authors', unchanged |
| 4 | NOAA index text files → the `[value year month]` layout the authors' script expects; ONI's 3-month seasons go to their centre month | Ours (format only) |
| 5 | Smoothed PCs correlated with ONI and PDO | Authors', unchanged |
| 6 | Correlate all 8 PCs with both indices; smoothing window 30 (code) vs 20 (methods text) | Ours |
| 7 | Maps on the published ±0.8 scale (the script uses ±1); 3E and 3F | Ours |
| 8 | Coordinate checks | Ours |

## Deviations (all written to the log)
- **Year levels:** 20 instead of the data's 21 (step Y).
- **Missing toolbox:** without the Signal Processing Toolbox, a stand-in replaces CDT's `plotpsd`. It affects only the spectrum plots.
- **Missing ocean mask:** the all-true mask, as in every figure.
- **EOF signs:** they are arbitrary. The authors plot −PC5 against ONI, so compare |R|.

## Expected results (run of 18 Nov 2026, MATLAB R2024a)
| Quantity | Ours | Published |
|---|---|---|
| \|R\| PC5 vs ONI (30-point smoothing, as in the code) | 0.837 (P = 1.8 × 10⁻²³⁶) | 0.81 (P < 10⁻²¹⁶) |
| \|R\| PC6 vs PDO | 0.609 (P = 2.6 × 10⁻⁹²) | 0.59 (P < 10⁻⁸⁵) |
| Same with 20-point smoothing (as in the methods text) | 0.824 / 0.572 | 0.81 / 0.59 |
| Mode most correlated with ONI / PDO | PC5 / PC6 | PC5 / PC6 |
| Sign of the PC5–ONI correlation | negative (−0.837) | negative (authors plot −PC5) |
| Variance explained by PC5 / PC6 | 1.42% / 0.99% | not stated |
| Year levels / ANOVA cells | 20 / 22,468 | 20 / 20,822 |
| Land cells empty / landmarks correct (3B, EOF 5) | 1.000 / 10 of 10 | — |

**Maps vs published panels** (`python fig3/compare_to_published.py <paper.pdf> fig3/outputs/fig3_results.mat`):

| Panel | Spearman | Pearson | Within ±0.1 |
|---|---|---|---|
| 3B 2011 | 0.83 | 0.73 | 81% |
| 3C 2015 | 0.82 | 0.83 | 81% |
| 3E PDO cool (reconstruction) | 0.81 | 0.63 | 98% |
| 3F PDO warm (reconstruction) | 0.86 | 0.45 | 98% |

The PDO-phase maps have small values near the white middle of the colour bar, where reading colours is least reliable, so Spearman and the within-tolerance share describe their agreement better than Pearson. The time series in 3A and 3D have the same peaks and troughs as the published ones (compare `outputs/step7_fig3_AD.png` with the paper).
