# Input data

Every input goes in this folder. The one exception is the `inpaint_nans` code, which goes in `deps/inpaint_nans/`.

`setup_data` (repository root) finds these files on your computer and copies them here. It prints a download link for anything it can't find.

## Included in the repository (small files)

| File | Source | Used for |
|---|---|---|
| `data_insitu_v2_25-04.csv` | Zenodo data record (doi:10.5281/zenodo.8064615; record 15168108) | Fig. 1B, 1C |
| `sat_data_25-04/genomic_OCmatchups_v3_medians_{1p,3p,5p,1d,2d,5d}.csv` | Same Zenodo record | Fig. 1B, 1C |

`data_insitu_v2_25-04.csv` has 1,137 metagenomic samples: location, date, Ω stress scores, *Prochlorococcus* core-gene coverage and ship measurements. The matchup files give satellite Θ′ for each sample over six spatial windows × 15 time windows. They are laid out exactly as the authors' R script expects.

## Added by you (large files, not committed to GitHub)

| File | Size | Source | Used for |
|---|---|---|---|
| `thetaPrime_MODIS.mat` | 111 MB | Dryad: https://datadryad.org/dataset/doi:10.5061/dryad.f4qrfj71p | Figs. 1A, 2, 3, 4 |
| `SST_v2_25-04.csv` | 661 MB | Zenodo: https://zenodo.org/records/15168108 | Fig. 4 |
| `woa23_all_n00_01.nc` | ~50 MB | NOAA NCEI: https://www.ncei.noaa.gov/data/oceans/woa/WOA23/DATA/nitrate/netcdf/all/1.00/woa23_all_n00_01.nc | Figs. 1A, 2B |
| `oni.ascii.txt` | small | NOAA CPC: https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt | Fig. 3 |
| `ersst.v5.pdo.dat` | small | NOAA NCEI: https://www.ncei.noaa.gov/pub/data/cmb/ersst/v5/index/ersst.v5.pdo.dat | Fig. 3 |
| `Dataset S1_WOD.csv` | ? | **Not released.** Possibly Dataset S1 of Gerace et al. 2025, *PNAS*, doi:10.1073/pnas.2411835122. It needs columns `lat_degN`, `lon_degE` and `Zno3_m` | Fig. 4D only (optional) |

Notes:
- **Θ′ file:** a 180 × 360 × 897 grid at 1°, with 8-day composites from 4 July 2002 to 1 January 2022 and land masked. The authors' scripts call it `thetaPrime_Dec24.mat`; the runners create that copy automatically.
- **Index files:** the paper says its indices came from NOAA and are based on ERSST v5. The Fig. 3 runner also accepts other NOAA layouts, as long as the file names contain "oni" and "pdo".
- **Large-file size:** the WOA23 file size is approximate.
