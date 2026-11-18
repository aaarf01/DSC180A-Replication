"""Compare the Fig. 2 run with the published Fig. 2A and 2C-F by digitizing panel colours.

Usage:
    python fig2/compare_to_published.py <paper.pdf> fig2/outputs/fig2_results.mat [fig2/outputs/fig2_vs_published.png]

Requires poppler (pdftoppm) and Python with numpy, scipy, pillow, matplotlib. The paper PDF is not
included in this repository (copyright); download it from https://doi.org/10.1126/sciadv.aed8089.

Method: page 3 of the PDF is rendered at 300 dpi with pdftoppm (poppler). Each 1-degree
cell is sampled at its centre pixel, and the colour is converted to a value via the
panel's own colour bar (nearest colour). The panel frames and colour bars below were
located from frame lines and tick marks in the 300-dpi render, and the small offsets by
maximizing land-mask agreement. Near-white pixels are treated as blank (land or masked).

Caveat: the digitized values carry artifacts. Near-white edge pixels read as mid-scale,
and dark lines or text read as scale ends. Correlations are therefore lower bounds; the
share of cells within +/-0.25 is less distorted by these artifacts.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import scipy.io as sio
from PIL import Image
from scipy import ndimage, stats

pdf, resfile = Path(sys.argv[1]), Path(sys.argv[2])
outpng = Path(sys.argv[3]) if len(sys.argv) > 3 else None

with tempfile.TemporaryDirectory() as td:
    subprocess.run(["pdftoppm", "-f", "3", "-l", "3", "-r", "300", "-png", str(pdf), f"{td}/p"], check=True)
    im = np.asarray(Image.open(next(Path(td).glob("p*.png"))).convert("RGB")).astype(float)

r = sio.loadmat(resfile)
M, Season = r["M"], r["Season"]
LON2, LAT = r["LON2"].ravel(), r["LATband"].ravel()
ocean = np.isfinite(M)


def sample(x0, x1, y0, y1, dx=0.0, dy=0.0):
    # frames span longitude 20..380 and latitude 41..-41 (cell edges)
    X = x0 + (LON2 - 20) * (x1 - x0) / 360 + dx
    Y = y0 + (41 - LAT) * (y1 - y0) / 82 + dy
    return im[np.round(Y).astype(int)[:, None], np.round(X).astype(int)[None, :]]


def decode(P, cb, vals):
    d = ((P[..., None, :] - cb[None, None, :, :]) ** 2).sum(-1)
    return vals[d.argmin(-1)]


cbA = im[300, 953:1243]                     # Fig. 2A colour bar, 0..4, horizontal
valsA = np.linspace(0, 4, cbA.shape[0])
cbC = im[951:1111, 2255][::-1]              # Fig. 2C-F colour bar, -1.5..1.5, vertical
valsC = np.linspace(-1.5, 1.5, cbC.shape[0])

panels = [("2A", "Mean theta'", np.clip(M, 0, 4), sample(227.5, 1255, 329, 843, -2, 3), cbA, valsA, 248, (0, 4))]
for nm, mi, (x0, x1), dx, mn in zip("CDEF", [0, 3, 6, 9],
                                    [(227.5, 717), (735, 1225), (1239.5, 1729), (1738.5, 2228.5)],
                                    [0, 0.5, -1, 0], ["January", "April", "July", "October"]):
    panels.append(("2" + nm, mn + " anomaly", np.clip(Season[:, :, mi], -1.5, 1.5),
                   sample(x0, x1, 928, 1150.5, dx, 1), cbC, valsC, 250, (-1.5, 1.5)))

# Land-mask comparison (panel A): cells with data in our run but blank in the paper
PA = panels[0][3]
pubBlank = PA.min(2) > 248
extra = ocean & pubBlank
dist = ndimage.distance_transform_edt(ocean)
print(f"Panel A land agreement: {(pubBlank == ~ocean).mean():.3f}")
print(f"Cells with data in our run but blank in the paper: {extra.sum()} "
      f"(median distance to land {np.median(dist[extra]):.1f} cells; "
      f"{100 * (dist[extra] <= 2).mean():.0f}% within 2 cells of land, vs "
      f"{100 * (dist[ocean] <= 2).mean():.0f}% of all cells)")

print(f"\n{'panel':6}{'n':>8}{'Pearson':>9}{'Spearman':>10}{'med|diff|':>11}{'within0.25':>12}")
results = []
for nm, title, o, P, cb, vals, thr, lim in panels:
    p = decode(P, cb, vals)
    b = ocean & ~(P.min(2) > thr)
    pr, sp = stats.pearsonr(o[b], p[b])[0], stats.spearmanr(o[b], p[b])[0]
    print(f"{nm:6}{b.sum():8d}{pr:9.3f}{sp:10.3f}{np.median(abs(o[b] - p[b])):11.3f}"
          f"{100 * np.mean(abs(o[b] - p[b]) <= 0.25):11.1f}%")
    results.append((nm, title, o[b], p[b], pr, lim))

if outpng:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(1, 5, figsize=(17, 3.8))
    for a, (nm, title, o, p, pr, lim) in zip(ax, results):
        a.hexbin(o, p, gridsize=45, bins="log", cmap="Greys", extent=(*lim, *lim))
        a.plot(lim, lim, color="#c0392b", lw=1)
        a.set_title(f"Fig. {nm}: {title}\nr = {pr:.2f}, n = {o.size:,}", fontsize=10)
        a.set_xlabel("Our run"); a.set_xlim(lim); a.set_ylim(lim); a.set_aspect("equal")
    ax[0].set_ylabel("Published (digitized)")
    plt.suptitle("Fig. 2: our values vs values read from the published panels (red = 1:1). "
                 "Horizontal bands are digitizing artifacts.", fontsize=11)
    plt.tight_layout()
    plt.savefig(outpng, dpi=130)
