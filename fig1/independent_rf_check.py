"""Independent cross-check of Fig. 1B with scikit-learn.

NOT the authors' code and NOT a reproduction. It approximates R randomForest
regression defaults (500 trees, mtry = max(floor(p/3), 1), nodesize 5,
bootstrap sampling, out-of-bag R^2). Different RNG and tree-building details
mean values should be close to, but not identical with, the R output.

Usage (from the repository root): python fig1/independent_rf_check.py .
"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor

root = Path(sys.argv[1])
ins = pd.read_csv(root / "data" / "data_insitu_v2_25-04.csv")
sat = pd.read_csv(root / "data" / "sat_data_25-04" / "genomic_OCmatchups_v3_medians_2d.csv",
                  encoding="utf-8-sig")

y_all = sat.iloc[:, 9].to_numpy()          # column 10 = +/-20 days, as in the R script
keep = ~np.isnan(y_all)
y = y_all[keep]
predictors = ["insitu_and_woa_nutricline", "Omega_P_High", "Omega_N_High",
              "Omega_N_Med", "Omega_Fe_High", "Omega_Fe_Med"]
X_full = ins.loc[keep, predictors].to_numpy()
X_nut = X_full[:, :1]


def oob_r2(X, seed):
    p = X.shape[1]
    rf = RandomForestRegressor(n_estimators=500, max_features=max(p // 3, 1),
                               min_samples_split=6, bootstrap=True, oob_score=True,
                               random_state=seed, n_jobs=-1)
    rf.fit(X, y)
    # same definition as the R script: 1 - MSE_oob / population variance of y
    mse = np.mean((y - rf.oob_prediction_) ** 2)
    return 1 - mse / np.var(y)


seeds = range(20)
r_nut = np.array([oob_r2(X_nut, s) for s in seeds])
r_full = np.array([oob_r2(X_full, s) for s in seeds])
print(f"rows in file: {len(ins)}; samples used (non-missing theta'): {keep.sum()}")
print(f"nutricline only        : mean {r_nut.mean():.3f}  range {r_nut.min():.3f}-{r_nut.max():.3f}")
print(f"nutricline + biomarkers: mean {r_full.mean():.3f}  range {r_full.min():.3f}-{r_full.max():.3f}")
print(f"ratio of means: {r_full.mean() / r_nut.mean():.2f}")
