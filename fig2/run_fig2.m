function run_fig2
% Fig. 2 of Martiny et al. (2026, Sci. Adv.): mean theta' (2A), nutricline depth (2B),
% monthly theta' anomalies (2C-F), plus the 59%-seasonal-variance claim.
% Needs: data/thetaPrime_MODIS.mat (all panels), data/woa23_all_n00_01.nc (2B only).
%   >> run_fig2          (from this folder, or via run_all at the repository root)
%
% Steps and how faithful each one is:
%   P. prepare_time_files.m + preprocess_..._bathy.m     authors' (unchanged / path-only patch), via common/
%   1. global_geomean_figure_v5.m  -> Fig. 2A            authors', path-only patch
%   2. ANOVA_analysis.m            -> per-cell ANOVA     authors', one-line fix (preallocation too small)
%   3. ANOVA_monthly.m             -> monthly anomalies  authors', unchanged (all 12 months = fig. S7)
%   4. ANOVA_variance.m            -> variance shares    authors', unchanged (colormap file supplied)
%   5. Coordinate checks                                  ours
%   6. Fig. 2C-F four-panel figure                        ours (plots the authors' outputs)
%   7. Month-assignment and anomaly-baseline checks       ours
%   8. Fig. 2B from WOA23                                 OUR reconstruction (no script released)

figDir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(figDir), 'common', 'matlab'));
if ~exist(fullfile(figDir, 'outputs'), 'dir'), mkdir(fullfile(figDir, 'outputs')); end
start_log(fullfile(figDir, 'outputs', 'fig2_run_log.txt'));
oldDir = pwd;
restore = onCleanup(@() finish(oldDir));
try
    do_run(figDir);
catch ME
    fprintf('\nRUN FAILED:\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
end
end

function do_run(figDir)
tAll = tic;
fprintf('=== Fig. 2 reproduction ===\n');
env = figure_env(figDir);
root = env.root; work = env.work; out = env.out;
f2a = fullfile(work, 'fig2A');
for d = {f2a, fullfile(f2a, 'cdt'), fullfile(f2a, 'colorbrewer')}
    if ~exist(d{1}, 'dir'), mkdir(d{1}); end
end
require_functions({'anovan', 'geomean', 'smooth', 'inpaint_nans', 'brewermap', 'cmocean', 'imagescn', 'clim'});
[~, ok] = input_path(root, 'theta');
if ~ok, error('data/thetaPrime_MODIS.mat not found. Run setup_data first (see README).'); end

%% Step P: preprocessing (shared code, identical for every figure)
G = prep_theta(root, work, out);
P = load(fullfile(work, 'DataLL_theta.mat'));
T = load(fullfile(work, 'time.mat'));
fprintf('Time axis: %s to %s; year values %s\n', datestr(T.timenum(1), 'yyyy-mm-dd'), ...
    datestr(T.timenum(end), 'yyyy-mm-dd'), mat2str(unique(T.time_vec(:, 1))')); %#ok<DATST>

%% Step 1: Fig. 2A with the authors' geometric-mean script (path-only patch)
fprintf('\n=== Step 1: global_geomean_figure_v5 (path-only patch) -> Fig. 2A ===\n'); t = tic;
fprintf('Changes vs authors'' file: 5 path lines only (common/patches/global_geomean_PATHS.diff).\n');
% This script plots DATAlowLat3 without reordering longitude, so it needs the order the
% preprocessing script itself produces. The trend and ANOVA scripts need the opposite
% order. It therefore runs in its own folder with a preprocessing-order copy of the data.
DATAlowLat3 = P.DATAlowLat3(:, [201:360 1:200], :); %#ok<NASGU>
save(fullfile(f2a, 'DataLL_theta.mat'), 'DATAlowLat3');
clear DATAlowLat3
LAT2 = P.LAT(50:131); %#ok<NASGU>
save(fullfile(f2a, 'LAT2.mat'), 'LAT2');
LON2 = 20.5:379.5; %#ok<NASGU>
save(fullfile(f2a, 'LON3.mat'), 'LON2');
fprintf('DEVIATION: LAT2.mat and LON3.mat are not released; rebuilt as LAT(50:131) and LON2 = 20.5:379.5\n');
fprintf('           (the longitude vector every other script uses, consistent with this script''s tick labels).\n');
fprintf('DEVIATION: Fig. 2A runs on a copy of the data in the preprocessing script''s own output order,\n');
fprintf('           because this script, unlike the ANOVA and trend scripts, does not reorder longitude.\n');
W = run_in_base(copy_verified(root, fullfile('common', 'patches'), 'global_geomean_figure_v5_PATHS.m', f2a), {'M', 'LON2', 'LAT2'});
save_figs('step1_fig2A', out);
F2A = W;
fin = F2A.M(isfinite(F2A.M));
fprintf('Geometric-mean theta'': %d cells; median %.3f; 5th-95th percentile %.3f-%.3f; cells equal to 0: %d\n', ...
    numel(fin), median(fin), prctile(fin, 5), prctile(fin, 95), nnz(fin == 0));
fprintf('Step 1 done (%.0f s)\n', toc(t));

%% Step 2: per-cell ANOVA (one-line fix)
fprintf('\n=== Step 2: ANOVA_analysis (one-line preallocation fix) ===\n'); t = tic;
fprintf('Change vs authors'' file: Coefs = zeros(N,24) sized from the data instead\n');
fprintf('  (common/patches/ANOVA_analysis_PREALLOC.diff). With 24 columns the released script stops at\n');
fprintf('  the first cell, because anovan returns 1 + years + 12 coefficients.\n');
fprintf('Running anovan for every grid cell; this takes several minutes...\n');
W = run_in_base(copy_verified(root, fullfile('common', 'patches'), 'ANOVA_analysis_PREALLOC.m', work), {'Coefs', 'SSQ', 'ind'});
A = W;
nYr = numel(unique(T.time_vec(:, 1)));
fprintf('ANOVA grid cells: %d (paper: 20,822)\n', size(A.Coefs, 1));
fprintf('Coefficients per cell: %d = 1 constant + %d year levels + 12 month levels (paper: 20 year levels)\n', ...
    size(A.Coefs, 2), nYr);
fprintf('Step 2 done (%.1f min)\n', toc(t) / 60);

%% Step 3: monthly anomalies (unchanged)
fprintf('\n=== Step 3: ANOVA_monthly (unchanged) -> monthly anomalies (fig. S7) ===\n'); t = tic;
W = run_in_base(copy_verified(root, 'authors_code', 'ANOVA_monthly.m', work), {'Season', 'LAT', 'LON2'});
save_figs('step3_monthly_S7', out);
MON = W;
fprintf('Season array %s (lat x lon x month), display longitudes %.1f to %.1f\n', ...
    mat2str(size(MON.Season)), MON.LON2(1), MON.LON2(end));
fprintf('Step 3 done (%.0f s)\n', toc(t));

%% Step 4: share of variance explained (unchanged; colormap file supplied)
fprintf('\n=== Step 4: ANOVA_variance (unchanged) -> seasonal vs yearly variance ===\n'); t = tic;
copyfile(fullfile(root, 'common', 'shims', 'inferno_cmap.mat'), fullfile(work, 'inferno_cmap.mat'));
fprintf('inferno_cmap.mat is not released; supplied from matplotlib''s inferno (colours only).\n');
W = run_in_base(copy_verified(root, 'authors_code', 'ANOVA_variance.m', work), {'Mf_season', 'Mf_annual', 'SumSSQ'});
save_figs('step4_variance', out);
VAR = W;
fprintf('Median seasonal share of variance: %.3f (paper: 59%%)\n', VAR.Mf_season);
fprintf('Median yearly share of variance:   %.3f (paper: not stated)\n', VAR.Mf_annual);
fprintf('Step 4 done (%.0f s)\n', toc(t));

%% Step 5: coordinate checks (ours)
fprintf('\n=== Step 5: coordinate checks (OURS) ===\n');
% Display convention used by every map script: LON2 = 20.5:379.5, rows LAT(50:131) = 40.5N..40.5S.
expLon = mod([G.LONg(201:360) G.LONg(1:200)], 360);
fprintf('Display longitudes equal the reordered Dryad longitudes: %s\n', ...
    string(isequal(mod(MON.LON2, 360), expLon) && isequal(mod(F2A.LON2, 360), expLon)));
fprintf('Display latitudes run %.1f to %.1f (north at top): %s\n', MON.LAT(1), MON.LAT(end), ...
    string(isequal(MON.LAT(:)', G.LATband) && isequal(F2A.LAT2(:)', G.LATband)));
landDisp = G.landDisp;
chk.fig2A    = coord_check('Fig. 2A geometric mean', F2A.M, landDisp, F2A.LON2, G.LATband);
chk.january  = coord_check('Fig. 2C January anomaly', MON.Season(:, :, 1), landDisp, MON.LON2, G.LATband);
chk.seasonal = coord_check('Seasonal variance share', VAR.SumSSQ.frac_season, landDisp, MON.LON2, G.LATband);

%% Step 6: Fig. 2C-F panel (ours, from the authors' outputs)
fprintf('\n=== Step 6: Fig. 2C-F four-panel figure (OURS) ===\n');
f = figure('Color', 'w', 'Position', [100 100 1100 520]);
mnames = {'January', 'April', 'July', 'October'}; midx = [1 4 7 10];
for p = 1:4
    subplot(2, 2, p);
    imagescn(MON.LON2, MON.LAT, MON.Season(:, :, midx(p)));
    clim([-1.5 1.5]); cmocean('balance'); colorbar
    xticks([90 180 270 360]); xticklabels({'90E', '180E', '90W', '0'});
    title(sprintf('%s (%s)', mnames{p}, char('C' + p - 1)));
end
sgtitle('Fig. 2C-F reproduction: monthly \Theta'' anomalies (scale \pm1.5 as published)');
exportgraphics(f, fullfile(out, 'step6_fig2CF.png'), 'Resolution', 150);
savefig(f, fullfile(out, 'step6_fig2CF.fig')); close(f);
fprintf('NOTE: the authors'' ANOVA_monthly.m uses a +/-2 colour scale; the published panels use +/-1.5.\n');
fprintf('      The four-panel figure uses +/-1.5 to match the paper. The data are identical.\n');
for p = 1:4
    x = MON.Season(:, :, midx(p)); x = x(isfinite(x));
    fprintf('  %-8s anomaly: median %+.3f, 1st-99th pct %+.2f to %+.2f, beyond +/-1.5: %.1f%%\n', ...
        mnames{p}, median(x), prctile(x, 1), prctile(x, 99), 100 * mean(abs(x) > 1.5));
end

%% Step 7: monthly assignment and anomaly baseline (ours)
fprintf('\n=== Step 7: monthly assignment and anomaly-baseline checks (OURS) ===\n');
tv = T.time_vec; tn = T.timenum(:);
yrv = tv(:, 1); mo = tv(:, 2);
fprintf('-- 7a. How 8-day composites are assigned to months --\n');
fprintf('Each composite is one observation, labelled with the month of its START date\n');
fprintf('(prepare_time_files.m converts year + start day to month). Nothing is averaged to months first.\n');
cnt = accumarray(mo, 1, [12 1])';
fprintf('Composites per month (Jan..Dec): %s\n', mat2str(cnt));
yEnd = datenum(yrv, 12, 31);
endD = min(tn + 7, yEnd);                       % MODIS 8-day composites restart on 1 January
moEnd = month(datetime(endD, 'ConvertFrom', 'datenum'));
moMid = month(datetime(floor((tn + endD) / 2), 'ConvertFrom', 'datenum'));
fprintf('Composites spanning two calendar months: %d of %d (%.1f%%)\n', nnz(moEnd ~= mo), numel(mo), 100 * mean(moEnd ~= mo));
fprintf('Composites whose midpoint falls in a different month than their start: %d (%.1f%%)\n', ...
    nnz(moMid ~= mo), 100 * mean(moMid ~= mo));
fprintf('Year levels: %s; observations in 2022: %d\n', mat2str(unique(yrv)'), nnz(yrv == 2022));

data2 = reshape(P.DATAlowLat3, 29520, 897);
indC = ~isnan(sum(data2, 2));
assert(isequal(indC(:), A.ind(:)), 'Cell selection differs from ANOVA_analysis.m');
Y = data2(indC, :)';                            % 897 x cells, same column order as Coefs rows
clear data2

fprintf('\n-- 7b. Independent re-computation of the anovan coefficients --\n');
[mBase, yBase, cBase] = effects_ls(Y, yrv, mo);
mA = A.Coefs(:, end-11:end)'; yA = A.Coefs(:, 2:1+nYr)'; cA = A.Coefs(:, 1)';
fprintf('Least squares with sum-to-zero (effect) coding vs anovan output:\n');
fprintf('  max |difference|: constant %.2e, year effects %.2e, month effects %.2e\n', ...
    max(abs(cBase - cA)), max(abs(yBase - yA), [], 'all'), max(abs(mBase - mA), [], 'all'));
fprintf('  max |sum of the 12 month effects| per cell: %.2e (zero means the baseline is the\n', max(abs(sum(mA, 1))));
fprintf('  unweighted average over months, after removing year effects)\n');

fprintf('\n-- 7c. Baseline: ANOVA month effect vs a simple monthly climatology anomaly --\n');
climM = zeros(12, size(Y, 2));
for m = 1:12, climM(m, :) = mean(Y(mo == m, :), 1); end
naive = climM - mean(climM, 1);
cmp_effects('Simple climatology (month mean - mean of 12 months)', naive, mA);

fprintf('\n-- 7d. Sensitivity: month taken from the composite midpoint --\n');
mMid = effects_ls(Y, yrv, moMid);
cmp_effects('Midpoint-month ANOVA', mMid, mA);

fprintf('\n-- 7e. Sensitivity: 2022/001 composite counted as 2021 (20 year levels, as in the paper) --\n');
yr20 = yrv; yr20(yr20 == 2022) = 2021;
m20 = effects_ls(Y, yr20, mo);
cmp_effects('20-year-level ANOVA', m20, mA);

%% Step 8: Fig. 2B nutricline depth from WOA23 (OUR reconstruction; no authors' script)
fprintf('\n=== Step 8: Fig. 2B nutricline depth from WOA23 (OURS) ===\n');
[fW, hasW] = input_path(root, 'woa');
B2 = struct('done', false, 'median', NaN, 'n', 0);
if ~hasW
    fprintf('SKIPPED: data/woa23_all_n00_01.nc not found (run setup_data or download it; see README).\n');
else
    [Zg, winfo] = woa_nutricline(fW, 3);
    fprintf('Nitrate units: %s. Threshold 3 (3 umol/L = ~2.93 umol/kg, negligible).\n', winfo.units);
    fprintf('Depth levels: %d (%.0f to %.0f m). Profiles %d; surface >= 3 (set to 0 m): %d; never reach 3 (blank): %d\n', ...
        numel(winfo.depth), winfo.depth(1), winfo.depth(end), winfo.nProfiles, winfo.nSurfaceAbove, winfo.nNeverReaches);
    fprintf('CHOICES (paper silent): annual climatology (n00), all decades, n_an; linear interpolation between\n');
    fprintf('  standard depths; surface >= 3 -> 0 m; never reaching 3 -> blank; masked to cells with theta'' data.\n');
    assert(isequal(winfo.lon, -179.5:179.5) && isequal(winfo.lat, -89.5:89.5), 'Unexpected WOA grid');
    rows = arrayfun(@(la) find(winfo.lat == la), MON.LAT);
    Zd = Zg(rows, [201:360 1:200]);
    Z = Zd; Z(~isfinite(F2A.M)) = NaN;
    x = Z(isfinite(Z));
    fprintf('Theta'' cells: %d; with a nutricline value: %d\n', nnz(isfinite(F2A.M)), numel(x));
    fprintf('Nutricline: median %.0f m; 5th-95th pct %.0f-%.0f m; at 0 m %.1f%%; <30 m %.1f%%; >250 m %.1f%%\n', ...
        median(x), prctile(x, 5), prctile(x, 95), 100 * mean(x == 0), 100 * mean(x < 30), 100 * mean(x > 250));
    chk.fig2B = coord_check('Fig. 2B nutricline', Z, G.landDisp, MON.LON2, G.LATband);
    f = figure('Color', 'w', 'Position', [100 100 900 420]);
    imagescn(MON.LON2, MON.LAT, Z); clim([30 250]); colormap(brewermap(256, 'Spectral')); colorbar
    xticks([45 90 135 180 225 270 315 360]); xticklabels({'45E', '90E', '135E', '180E', '135W', '90W', '45W', '0'});
    title('Fig. 2B reconstruction: nutricline depth Z_{NO3} (3 \muM), WOA23 annual (m)');
    exportgraphics(f, fullfile(out, 'step8_fig2B.png'), 'Resolution', 150);
    savefig(f, fullfile(out, 'step8_fig2B.fig')); close(f);
    B2.done = true; B2.median = median(x); B2.n = numel(x); B2.Z = Z;
end

%% Summary
fprintf('\n=== Summary ===\n');
q   = {'Median seasonal share of variance'; 'Median yearly share of variance'; 'ANOVA grid cells'; ...
       'Year levels in ANOVA'; 'Month levels in ANOVA'; 'Fig. 2A median geometric-mean theta'''; ...
       'Fig. 2A land cells correctly empty'; 'Fig. 2C land cells correctly empty'; ...
       'Max |anovan - independent least squares|'; 'Fig. 2B median nutricline (m)'; 'Fig. 2B cells with a value'};
ours = [VAR.Mf_season; VAR.Mf_annual; size(A.Coefs, 1); nYr; 12; median(fin); ...
        chk.fig2A.landEmpty; chk.january.landEmpty; max(abs(mBase - mA), [], 'all'); B2.median; B2.n];
pub  = {'0.59'; 'not stated'; '20822'; '20'; '12'; 'not stated (colour scale 0-4)'; ...
        '1 expected'; '1 expected'; '0 expected'; 'not stated (colour scale 30-250)'; 'not stated'};
Tsum = table(q, ours, pub, 'VariableNames', {'quantity', 'reproduced', 'published_or_expected'});
disp(Tsum)
writetable(Tsum, fullfile(out, 'fig2_summary.csv'));
Season = MON.Season; LON2 = MON.LON2; LATband = MON.LAT; M = F2A.M; SumSSQ = VAR.SumSSQ; %#ok<NASGU>
save(fullfile(out, 'fig2_results.mat'), 'Season', 'LON2', 'LATband', 'M', 'SumSSQ', 'chk', ...
     'mA', 'naive', 'mMid', 'm20', 'cnt', 'B2');
fprintf('Saved fig2_summary.csv and fig2_results.mat in outputs/\n');
fprintf('Total run time %.1f min\n', toc(tAll) / 60);
end

%% ------------------------------------------------------------------ helpers
function [mEff, yEff, c] = effects_ls(Y, yr, mo)
% Main-effects model fitted by least squares with sum-to-zero (effect) coding.
[Xy, Ly] = effcode(yr); [Xm, ~] = effcode(mo);
B = [ones(numel(yr), 1) Xy Xm] \ Y;
c = B(1, :);
by = B(2:Ly, :);           yEff = [by; -sum(by, 1)];
bm = B(Ly+1:Ly+11, :);     mEff = [bm; -sum(bm, 1)];
end

function [X, L] = effcode(g)
lv = unique(g); L = numel(lv);
X = zeros(numel(g), L - 1);
for i = 1:L-1, X(:, i) = (g == lv(i)) - (g == lv(L)); end
end

function cmp_effects(label, alt, base)
d = alt - base;
fprintf('%s vs authors'' anovan month effects:\n', label);
fprintf('  all months: max |diff| %.3f, RMS diff %.4f, cells x months with |diff| > 0.1: %.2f%%\n', ...
    max(abs(d), [], 'all'), sqrt(mean(d .^ 2, 'all')), 100 * mean(abs(d) > 0.1, 'all'));
names = {'Jan', 'Apr', 'Jul', 'Oct'}; idx = [1 4 7 10];
s = '';
for p = 1:4
    r = corrcoef(alt(idx(p), :), base(idx(p), :));
    s = [s sprintf('%s %.4f  ', names{p}, r(1, 2))]; %#ok<AGROW>
end
fprintf('  spatial pattern correlation (Fig. 2C-F months): %s\n', s);
end

function finish(oldDir)
cd(oldDir);
diary off
end
