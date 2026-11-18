"""Compare the Fig. 3 maps (3B, 3C, 3E, 3F) with the published panels by digitizing colours.

Usage (from the repository root):
    python fig3/compare_to_published.py <paper.pdf> fig3/outputs/fig3_results.mat

Requires poppler (pdftoppm) and Python with numpy, scipy and pillow. The paper PDF is not
included in this repository (copyright); download it from https://doi.org/10.1126/sciadv.aed8089.

Method: page 4 of the PDF is rendered at 300 dpi. Each 1-degree cell is sampled at its centre
pixel and the colour converted to a value with the panel's colour bar (-0.8 to 0.8). Panel
frames and the colour bar were located from frame lines in the 300-dpi render; a small offset
per panel is chosen by maximizing land-mask agreement. Near-white pixels count as blank.

Caveat: values near zero are near-white and hardest to read, and dark lines or text read as
scale ends. Rank correlation (Spearman) and the share of cells within +/-0.1 are therefore
more reliable than Pearson r, especially for the low-amplitude PDO-phase maps (3E, 3F).
"""
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import scipy.io as sio
from PIL import Image
from scipy import stats

pdf, resfile = Path(sys.argv[1]), Path(sys.argv[2])
with tempfile.TemporaryDirectory() as td:
    subprocess.run(["pdftoppm", "-f", "4", "-l", "4", "-r", "300", "-png", str(pdf), f"{td}/p"], check=True)
    im = np.asarray(Image.open(next(Path(td).glob("p*.png"))).convert("RGB")).astype(float)

r = sio.loadmat(resfile)
A, yrs = r["Annual"], list(r["years"].ravel())
LON2, LAT = r["LON2"].ravel(), r["LATb"].ravel()
maps = {"3B 2011": A[:, :, yrs.index(2011)], "3C 2015": A[:, :, yrs.index(2015)],
        "3E PDO cool (reconstruction)": r["Mcool"], "3F PDO warm (reconstruction)": r["Mwarm"]}
frames = {"3B 2011": (1447, 2234, 1231, 1530), "3C 2015": (1447, 2234, 1607, 1907),
          "3E PDO cool (reconstruction)": (1444.5, 2230.5, 1986, 2289),
          "3F PDO warm (reconstruction)": (1444.5, 2230.5, 2357, 2660)}
cb = im[1641:1945, 2285][::-1]              # colour bar, bottom (-0.8) to top (+0.8)
vals = np.linspace(-0.8, 0.8, cb.shape[0])


def sample(fr, dx, dy):
    # frames span longitude 20..380 and latitude 41..-41 (cell edges), as in Fig. 2
    x0, x1, y0, y1 = fr
    X = x0 + (LON2 - 20) * (x1 - x0) / 360 + dx
    Y = y0 + (41 - LAT) * (y1 - y0) / 82 + dy
    Y = np.clip(np.round(Y).astype(int), 0, im.shape[0] - 1)
    return im[Y[:, None], np.round(X).astype(int)[None, :]]


ocean = np.isfinite(maps["3B 2011"])
print(f"{'panel':30}{'land agr.':>10}{'n':>7}{'Pearson':>9}{'Spearman':>10}{'med|diff|':>11}{'within0.1':>11}")
for nm, m in maps.items():
    best = max((((sample(frames[nm], dx, dy).min(2) > 248) == ~ocean).mean(), dx, dy)
               for dx in range(-3, 4) for dy in range(-3, 4))
    P = sample(frames[nm], best[1], best[2])
    blank = P.min(2) > 248
    pub = vals[((P[..., None, :] - cb[None, None]) ** 2).sum(-1).argmin(-1)]
    b = ocean & ~blank
    o = np.clip(m, -0.8, 0.8)
    print(f"{nm:30}{best[0]:10.3f}{b.sum():7d}{stats.pearsonr(o[b], pub[b])[0]:9.3f}"
          f"{stats.spearmanr(o[b], pub[b])[0]:10.3f}{np.median(abs(o[b] - pub[b])):11.3f}"
          f"{100 * np.mean(abs(o[b] - pub[b]) <= 0.1):10.1f}%")
