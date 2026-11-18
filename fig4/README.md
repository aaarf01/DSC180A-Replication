# Fig. 4: long-term trends, 2002–2021

| Panel | Content | Published | Method here |
|---|---|---|---|
| 4A | SST trend map | median +2.3 × 10⁻² °C/yr; 89% of area warming; +0.43 °C over the record | Authors' `longterm_SST_theta_overlay.m`, unchanged |
| 4B | Θ′ trend map | median −1.3 × 10⁻³ /yr | Same script |
| 4C | Histograms of both trends | — | Ours: the script computes these but never plots them |
| 4D | Mean trends by nutricline depth (>50 m / <50 m) and hemisphere, with 95% bootstrap CIs | bar chart | Authors' `trend_byRegion_wSST.m` (path edits) **and** a corrected version; needs an unreleased table |

## Run
`run_fig4` in MATLAB from this folder, or `run_all('fig4')` from the repository root. Takes about 3–5 minutes; reading the 661 MB SST file takes most of it.

## Inputs
| Panels | Needs |
|---|---|
| 4A–C | `data/thetaPrime_MODIS.mat`, `data/SST_v2_25-04.csv` |
| 4D | also `data/Dataset S1_WOD.csv` (skipped if missing; see below) |

## Outputs (`outputs/`)
| File | Contents |
|---|---|
| `fig4_run_log.txt` | every step, check and deviation |
| `fig4_summary.csv` | reproduced vs published values |
| `fig4_results.mat` | trend maps and statistics |
| `step2_fig4AB_fig1.png` | Θ′ and SST trend maps (4B, 4A) |
| `step2_fig4AB_fig2.png` | the authors' overlay map |
| `step3_fig4C.png` | 4C |
| `fig4D_results.csv` | 4D, if run |

## Steps
| Step | What | Code |
|---|---|---|
| P | Θ′ preprocessing (identical to Figs. 2 and 3) | Shared, `common/` |
| 1 | SST preprocessing | Ours (`prep_sst.m`); no authors' script exists |
| 2 | Per-cell linear trends, maps, medians and area statistics | Authors', unchanged |
| 3 | Fig. 4C histograms and summary | Ours |
| 4 | Fig. 4D, as released and corrected | Authors' (path edits) + ours |

## Deviations (all written to the log)
- **SST preprocessing is ours.**
  - **Steps:** the same as for Θ′, except clipping. That's an assumption, but all three SST statistics match the paper.
  - **Grid layout:** the SST file's layout isn't documented. `prep_sst.m` tests all four possible layouts against the Θ′ land mask and basic physical checks (warm equator, cool high latitudes, warm western Pacific). It stops if none is clearly right.
- **Longitude order:** the released preprocessing and trend scripts both reorder longitude, which would put the maps 200° off. The shared preprocessing saves data in the original order. This changes only where the maps are drawn, not any statistic.
- **Missing ocean mask:** the all-true mask, as in every figure.

## Fig. 4D: needs an unreleased table
- **What's missing:** the authors' script reads a nutricline table, `Dataset S1_WOD.csv`, with columns `lat_degN`, `lon_degE` and `Zno3_m`. It wasn't released.
- **Possible source:** Dataset S1 of Gerace et al. 2025 (*PNAS*, doi:10.1073/pnas.2411835122), a 3 μmol/kg nutricline database built from World Ocean Database profiles. If you find it, save it as `data/Dataset S1_WOD.csv`.
- **Problems in the released script** (found by reading it and simulating its indexing):
  - **Wrong longitudes:** `MLON = repmat(LON',82,1)` gives 99.7% of grid cells the wrong longitude (median error 90°); latitudes are correct. Hemisphere groupings survive, but each trend is matched to a nutricline from elsewhere in the ocean.
  - **Possible zero trends:** rows that match no grid cell may be kept as zero trends, because a new table variable is zero-filled. The log counts exact zeros.
  - **No random seed:** none is set for the bootstrap. We fix `rng(0)`.
- **What we report:**
  - **As released:** the authors' script with path edits only.
  - **Corrected:** correct cell pairing, with table longitudes wrapped into the script's 20–380° range.

## Expected results (identical in the runs of 4 and 18 Nov 2026, MATLAB R2024a)
| Quantity | Ours | Published |
|---|---|---|
| Median Θ′ trend (/yr) | −1.2254 × 10⁻³ | −1.3 × 10⁻³ |
| Median SST trend (°C/yr) | 2.3411 × 10⁻² | 2.3 × 10⁻² |
| Area fraction with SST increase | 0.887 | 0.89 |
| Average SST rise over the record (°C) | 0.431 | 0.43 |
| Area fraction with Θ′ increase | 0.431 | not stated |
| R, Θ′ trend vs SST trend | −0.191 | not stated |
| Grid cells with a Θ′ trend | 22,468 | 22,468 (code comment) / 20,822 (paper) |

The maps match the published geography: land-mask agreement with the paper is 93% for Θ′ and 91% for SST.
