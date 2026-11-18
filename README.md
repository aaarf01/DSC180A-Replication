# Replication of Martiny et al. (2026), *Science Advances*

This repository reproduces the computational results of:

> Martiny et al. (2026). Genomic-to-space measurements reveal global ocean nutrient stress. *Science Advances* 12(23), eaed8089. https://doi.org/10.1126/sciadv.aed8089

The paper builds a satellite index of phytoplankton nutrient stress, Θ′. Θ′ is the ratio of the carbon-to-chlorophyll ratio expected from light alone to the ratio observed by the MODIS-Aqua satellite; low Θ′ means more stress. The paper checks Θ′ against genomic stress biomarkers (Ω) from *Prochlorococcus* metagenomes, maps its seasonal and year-to-year variability, links it to El Niño and the Pacific Decadal Oscillation, and estimates trends over 2002–2021.

**Team:** _[names to be added]_ · **Licence for our code:** _[to be added]_

---

## Quick start

You need **MATLAB** (R2022a or later, with the Statistics and Machine Learning Toolbox and the Curve Fitting Toolbox) and **R** (4.x) with four packages. Details are under [Requirements](#requirements).

**1. Get the input data** (once). The large data files aren't stored in this repository.
- If you already have them somewhere on your computer, put this repository folder next to them and run, in MATLAB from the repository root:
  ```matlab
  setup_data
  ```
  It searches the folder that contains this repository and copies every input it finds into place. To search a different folder, pass it: `setup_data('/path/to/folder')`.
- For anything still missing, `setup_data` prints a download link. Download the file, put it in `data/`, and run `setup_data` again to confirm. [data/README.md](data/README.md) lists every file.

**2. Run everything:**
```matlab
run_all
```
This reproduces every figure in turn, which takes about 10–15 minutes. Figure windows open and close by themselves. To run only some figures, name them, e.g. `run_all('fig3')`.

**3. Check the results.**
- **One table of everything:** `results_summary.csv` in the repository root lists every key number, with our value next to the published one.
- **Per-figure detail:** each figure writes a log, a summary table and figures to `figN/outputs/`. Compare them with the expected values in each figure's README.
- **One file to share:** all outputs are also bundled into `results_<date-time>.zip` in the repository root.

---

## What is reproduced

Full numbers and comparisons are in **[RESULTS.md](RESULTS.md)**.

| Figure | Panels | How | Result |
|---|---|---|---|
| [Fig. 1](fig1/README.md) | 1A Θ′ vs nutricline depth | Our reconstruction (no code released) | Reproduced: R = −0.513 vs −0.52 |
| | 1B random forest R² | Authors' R script, unchanged | Reproduced: 0.342 / 0.605 vs ~0.36 / ~0.62 |
| | 1C Θ′ by dominant stress type | Our reconstruction | Reproduced: 6/6 signs, r = 0.95 with the published bars |
| | 1D Θ′ vs gene traits | — | Not reproducible: data not released |
| [Fig. 2](fig2/README.md) | 2A mean Θ′ map | Authors' script (path edits only) | Reproduced: 89% of cells within ±0.25 of published |
| | 2B nutricline depth map | Our reconstruction from WOA23 | Reproduced (visual comparison) |
| | 2C–F monthly anomalies | Authors' scripts (one-line fix) | Reproduced: 89–92% of cells within ±0.25 |
| | 59% seasonal variance | Authors' script | Not matched: 0.528 |
| [Fig. 3](fig3/README.md) | 3A, 3D EOF modes vs ENSO and PDO | Authors' scripts | Reproduced: \|R\| 0.84 / 0.61 vs 0.81 / 0.59 |
| | 3B, 3C 2011 and 2015 maps | Authors' scripts (one-line fix) | Reproduced: Spearman 0.83 / 0.82 with published |
| | 3E, 3F PDO-phase maps | Our reconstruction | Reproduced: Spearman 0.81 / 0.86 with published |
| [Fig. 4](fig4/README.md) | 4A–C trend maps and histograms | Authors' script, unchanged (histograms ours) | Reproduced: SST statistics match; Θ′ median −1.23 vs −1.3 × 10⁻³ |
| | 4D trends by region | Authors' script plus a corrected version | Blocked: input table not released |

## Repository layout

```
├── setup_data.m      finds and copies input files (step 1)
├── run_all.m         runs every figure (step 2)
├── data/             all inputs; small CSVs included, large files added by setup_data
├── authors_code/     the authors' original scripts (v1.0.2), unmodified, with checksums
├── common/           code shared by several figures
│   ├── matlab/       preprocessing, checks, helpers
│   ├── patches/      minimal edits of authors' scripts, each with a .diff
│   └── shims/        small stand-ins for unreleased helper files
├── deps/             third-party MATLAB code: Climate Data Toolbox, BrewerMap, inpaint_nans
├── fig1/ … fig4/     one folder per figure: runner, README, outputs/ (and work/ for temporary files)
```

Each figure folder is self-contained. A figure never reads another figure's outputs; shared steps such as Θ′ preprocessing live in `common/` and run inside each figure's own `work/` folder.

## How faithful is this?

- **The authors' code is used wherever it exists, and it is verified.** Every run checks the files in `authors_code/` against the checksums of the published v1.0.2 release and stops if any file has changed.
- **Edits are minimal and visible.** Where an authors' script can't run as released, the edit is a separate copy in `common/patches/` with a `.diff` against the original. Most edits replace hardcoded paths from the authors' computer. One fixes a preallocation bug that stops `ANOVA_analysis.m` on its first grid cell.
- **Every deviation is logged.** Each run log states every deviation, assumption and substitute file as it happens.
- **Our own reconstructions are labelled.** Where no code was released (1A, 1C, 2B, 3E–F), the panel is our reconstruction from the paper's text and captions, and is labelled as such everywhere.
- **Scope.** Θ′ is not recomputed from raw satellite data: every analysis starts from the authors' processed Θ′ grid on Dryad.

## Known issues in the released materials

Each is described in detail in the relevant figure README.

1. **Longitude order.** The released scripts disagree on longitude order. Run together as released, they place maps 200° off. We handle this in the shared preprocessing and check every map against land masks and named landmarks.
2. **`ANOVA_analysis.m` can't run as released.** Its coefficient array is preallocated too small (one-line fix).
3. **Fig. 1B matchup grid.** The script loads the 1° file in place of the single-pixel file. This doesn't affect Fig. 1B itself.
4. **Fig. 4D pairing.** The script gives 99.7% of grid cells the wrong longitude.
5. **Unreleased inputs:**
   - the shallow-water mask (`BathyLL.mat`), which probably explains the paper's 20,822 cells vs our 22,468;
   - the Fig. 4D nutricline table;
   - the gene-trait data for Fig. 1D.
6. **Unexplained gaps:**
   - seasonal share of Θ′ variance: 0.528 vs 0.59 published;
   - median Θ′ trend: −1.23 vs −1.3 × 10⁻³;
   - Fig. 1B sample size: 1,091 vs 990.

## Requirements

- **MATLAB** R2022a or later (tested with R2024a), with:
  - Statistics and Machine Learning Toolbox;
  - Curve Fitting Toolbox;
  - Signal Processing Toolbox (optional): Fig. 3 uses a stand-in without it, which affects only a spectrum plot.
- **R** 4.x (tested with 4.4.1) with `randomForest`, `reshape`, `ggplot2` and `pdp`:
  ```r
  install.packages(c("randomForest", "reshape", "ggplot2", "pdp"))
  ```
  `run_all` finds R in the usual install locations. If it can't, run `Rscript fig1/fig1b.R` and `Rscript fig1/fig1c.R` from a terminal.
- **Python** 3 (optional), for independent checks: `fig1/independent_rf_check.py`, and `fig2/compare_to_published.py` and `fig3/compare_to_published.py` (these two need the paper PDF and poppler).
- **Third-party MATLAB code** is included in `deps/` with its licence:
  - Climate Data Toolbox and BrewerMap, both Apache-2.0;
  - `inpaint_nans` (MATLAB File Exchange #4551), which is copied in by `setup_data` from your earlier kits. Otherwise download it from the link `setup_data` prints and put its folder at `deps/inpaint_nans/`.

## Data and code sources

- **Satellite Θ′:** Dryad, doi:10.5061/dryad.f4qrfj71p
- **SST, field-sample table and satellite matchups:** Zenodo, records 15168108 and doi:10.5281/zenodo.8064615
- **Authors' code:** https://github.com/ljustick/genomic_to_space_nut_stress v1.0.2 (Zenodo 15168175)
- **World Ocean Atlas 2023 nitrate, ONI and PDO:** NOAA (links in [data/README.md](data/README.md))
