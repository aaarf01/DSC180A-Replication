function run_fig4
% Fig. 4 of Martiny et al. (2026, Sci. Adv.): long-term trends 2002-2021.
%   4A  SST trend map, 4B theta' trend map, plus the medians    authors' code (unchanged)
%   4C  histograms of both trends                              ours (authors compute, never plot)
%   4D  mean trends by nutricline depth and hemisphere         authors' code (path edits) AND a
%                                                              corrected version; needs an unreleased table
% Needs: data/thetaPrime_MODIS.mat, data/SST_v2_25-04.csv; 4D also data/Dataset S1_WOD.csv
%   >> run_fig4          (from this folder, or via run_all at the repository root)

figDir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(figDir), 'common', 'matlab'));
if ~exist(fullfile(figDir, 'outputs'), 'dir'), mkdir(fullfile(figDir, 'outputs')); end
start_log(fullfile(figDir, 'outputs', 'fig4_run_log.txt'));
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
fprintf('=== Fig. 4 reproduction ===\n');
env = figure_env(figDir);
root = env.root; work = env.work; out = env.out;
addpath(figDir);                                   % prep_sst.m
require_functions({'smooth', 'corr', 'inpaint_nans', 'trend', 'cdtgrid', 'cdtarea', 'imagescn', 'cmocean', 'bootci'});
[fTheta, okT] = input_path(root, 'theta');
[fSST, okS] = input_path(root, 'sst');
if ~okT || ~okS
    error('Fig. 4 needs data/thetaPrime_MODIS.mat and data/SST_v2_25-04.csv. Run setup_data first (see README).');
end

%% Step P: theta' preprocessing (shared code, identical for every figure)
G = prep_theta(root, work, out);
fprintf('NOTE: the released preprocessing reorders longitude before saving, and longterm_SST_theta_overlay.m\n');
fprintf('      reorders again; run back to back they rotate maps by 200 degrees. prep_theta saves the data in\n');
fprintf('      the original order so the trend maps land on the right geography. Trends themselves are unaffected.\n');
S = load(fTheta, 'yr', 'yd'); yr = S.yr; yd = S.yd; clear S

%% Step 1: SST preprocessing (ours; no authors' script exists)
fprintf('\n=== Step 1: SST preprocessing (OURS: no authors'' script) ===\n'); t = tic;
prep_sst(fSST, yr, yd, G.landG, G.LATg, G.LONg, fullfile(work, 'DataLL_SST.mat'));
fprintf('Step 1 done (%.0f s)\n', toc(t));

%% Step 2: authors' longterm_SST_theta_overlay.m (unchanged) -> Fig. 4A, 4B, medians
fprintf('\n=== Step 2: longterm_SST_theta_overlay.m (unchanged) -> Fig. 4A, 4B ===\n'); t = tic;
W = run_in_base(copy_verified(root, 'authors_code', 'longterm_SST_theta_overlay.m', work));
save_figs('step2_fig4AB', out);
fprintf('Step 2 done (%.0f s)\n', toc(t));
chk.thetaTrend = coord_check('Fig. 4B theta'' trend map', W.T, G.landDisp, W.LON2, G.LATband);

%% Step 3: Fig. 4C histograms (ours) and summary
fprintf('\n=== Step 3: Fig. 4C histograms (OURS) ===\n');
edges = W.edges;   % the authors define these bins but never use them
f = figure('Color', 'w');
histogram(W.T(:), edges, 'EdgeColor', 'none', 'FaceColor', [0.93 0.49 0.19]); hold on
histogram(W.T_sst(:), edges, 'EdgeColor', 'none', 'FaceColor', [0.36 0.55 0.85]); hold off
legend({'\Theta'' trend (yr^{-1})', 'SST trend (\circC yr^{-1})'}, 'Location', 'northwest');
xlabel('Environmental trend (yr^{-1})'); ylabel('Grid cells'); xlim([-0.1 0.1]);
title('Fig. 4C reproduction (histograms added by us)');
exportgraphics(f, fullfile(out, 'step3_fig4C.png'), 'Resolution', 150);
savefig(f, fullfile(out, 'step3_fig4C.fig')); close(f);
fprintf('NOTE: T_sst is taken after the authors'' line T_sst(isnan(T)) = NaN, so both histograms use the same cells.\n');

nT = nnz(~isnan(W.T));
q   = {'Median theta'' trend (yr^-1)'; 'Median SST trend (degC yr^-1)'; ...
       'Area fraction with SST increase'; 'Average SST rise over record (degC)'; ...
       'Area fraction with theta'' increase'; 'Pearson R, theta'' trend vs SST trend'; ...
       'Grid cells with a theta'' trend'; 'Fig. 4B land cells correctly empty'};
ours = [W.Median_theta; W.Median_SST; W.R_sst; W.SST.period; W.R_theta; W.R; nT; chk.thetaTrend.landEmpty];
pub  = {'-1.3e-3'; '2.3e-2'; '0.89'; '0.43'; 'not stated'; 'not stated'; ...
        '22468 (code comment) / 20822 (paper)'; '1 expected'};
srcVar = {'Median_theta'; 'Median_SST'; 'R_sst'; 'SST.period'; 'R_theta'; 'R'; 'nnz(~isnan(T))'; 'check'};
Tsum = table(q, ours, pub, srcVar, 'VariableNames', {'quantity', 'reproduced', 'published', 'script_variable'});
disp(Tsum)
writetable(Tsum, fullfile(out, 'fig4_summary.csv'));
res = rmfield(W, intersect(fieldnames(W), {'data', 'data_sst', 'DATAlowLat3'}));
save(fullfile(out, 'fig4_results.mat'), '-struct', 'res');

%% Step 4: Fig. 4D (only if the nutricline table is available)
fprintf('\n=== Step 4: Fig. 4D ===\n');
[fW, okW] = input_path(root, 'wod');
if ~okW
    fprintf('SKIPPED: data/Dataset S1_WOD.csv not found. Fig. 4D needs this nutricline table, which was not\n');
    fprintf('released with the paper (see fig4/README.md).\n');
else
    run_fig4D(root, work, out, fW, G);
end
fprintf('\nSaved fig4_summary.csv and fig4_results.mat in fig4/outputs/\n');
fprintf('Total run time %.1f min\n', toc(tAll) / 60);
end

function run_fig4D(root, work, out, fW, G)
% Two versions:
%   AS RELEASED - authors' trend_byRegion_wSST.m with path-only edits. Its grid pairing
%                 (repmat(LON',82,1)) gives most cells the wrong longitude (latitude is right).
%   CORRECTED   - ours: same calculation with correct cell pairing, and table longitudes
%                 wrapped into the script's 20..380 range.
d = fullfile(work, 'fig4D');
for x = {d, fullfile(d, 'ByRegion'), fullfile(d, 'cdt')}
    if ~exist(x{1}, 'dir'), mkdir(x{1}); end
end
Wt = readtable(fW);
need = {'lat_degN', 'lon_degE', 'Zno3_m'};
assert(all(ismember(need, Wt.Properties.VariableNames)), ...
    'Table must have columns %s; found: %s', strjoin(need, ', '), strjoin(Wt.Properties.VariableNames, ', '));
fprintf('Nutricline table: %d rows; lat %.2f to %.2f; lon %.2f to %.2f; Zno3 %.1f to %.1f m\n', height(Wt), ...
    min(Wt.lat_degN), max(Wt.lat_degN), min(Wt.lon_degE), max(Wt.lon_degE), min(Wt.Zno3_m), max(Wt.Zno3_m));
fprintf('Integer-valued coordinates (the script shifts them by 0.5 to cell centres): lat %s, lon %s\n', ...
    string(all(Wt.lat_degN == round(Wt.lat_degN))), string(all(Wt.lon_degE == round(Wt.lon_degE))));
copyfile(fW, fullfile(d, 'ByRegion', 'Dataset S1_WOD.csv'));

P = load(fullfile(work, 'DataLL_theta.mat'));
S = load(fullfile(work, 'DataLL_SST.mat'));
T = load(fullfile(work, 'time.mat'));
% This script does not reorder longitude and labels columns with LON2 = 20.5:379.5,
% so it gets display-order copies (same approach as Fig. 2A).
DATAlowLat3 = P.DATAlowLat3(:, [201:360 1:200], :); save(fullfile(d, 'DataLL_theta.mat'), 'DATAlowLat3');
thetaD = DATAlowLat3;
DATAlowLat3 = S.DATAlowLat3(:, [201:360 1:200], :); save(fullfile(d, 'DataLL_SST.mat'), 'DATAlowLat3');
sstD = DATAlowLat3; clear DATAlowLat3 S
copyfile(fullfile(work, 'time.mat'), fullfile(d, 'time.mat'));
LON2 = 20.5:379.5; save(fullfile(d, 'LON2.mat'), 'LON2');
LAT = P.LAT; save(fullfile(d, 'LAT.mat'), 'LAT'); clear P
fprintf('DEVIATION: LON2.mat and LAT.mat rebuilt (LON2 = 20.5:379.5; LAT = Dryad latitudes).\n');
fprintf('DEVIATION: data passed in display longitude order, because this script does not reorder.\n');

fprintf('\n-- AS RELEASED: trend_byRegion_wSST.m (path-only patch, common/patches/trend_byRegion_PATHS.diff) --\n');
rng(0);
fprintf('Random seed fixed (rng(0)) so the bootstrap CIs are repeatable; the authors set none.\n');
Wr = run_in_base(copy_verified(root, fullfile('common', 'patches'), 'trend_byRegion_wSST_PATHS.m', d), {'result', 'result2', 'T_WOD'});
save_figs('step4_fig4D_as_released', out);
fprintf('Rows kept by the authors'' script: %d of %d; of these, theta_trend exactly 0: %d\n', ...
    height(Wr.T_WOD), height(Wt), nnz(Wr.T_WOD.theta_trend == 0));
fprintf('  (A new table variable created by indexed assignment is zero-filled, so rows that matched no\n');
fprintf('   grid cell may survive the script''s NaN filter as zero trends. Exact zeros flag such rows.)\n');

fprintf('\n-- CORRECTED pairing (OURS) --\n');
LATb = LAT(50:131); LATb = LATb(:)';
Tth = 365.25 * trend(thetaD, T.timenum, 3);
Tss = 365.25 * trend(sstD, T.timenum, 3);
[LONm, LATm] = meshgrid(LON2, LATb);              % 82 x 360, matches the arrays cell for cell
lat = Wt.lat_degN - 0.5; lon = Wt.lon_degE + 0.5;  % same shift as the authors' script
lonw = mod(lon - 20, 360) + 20;                    % wrap into 20..380
keep = abs(lat) < 40.6;
[tf, loc] = ismember([lat lonw], [LATm(:) LONm(:)], 'rows');
fprintf('Rows inside 40.6S-40.6N: %d; matched to grid cells: %d\n', nnz(keep), nnz(tf & keep));
fprintf('Rows matched only because of the longitude wrap: %d\n', nnz(tf & keep & lon < 20));
th = nan(height(Wt), 1); ss = th;
th(tf) = Tth(loc(tf)); ss(tf) = Tss(loc(tf));
ok = keep & isfinite(th);
Z = Wt.Zno3_m; la = lat;
groups = {'All', ok; '>50 m', ok & Z > 50; '<50 m', ok & Z < 50; 'NH >50 m', ok & Z > 50 & la > 0; ...
          'NH <50 m', ok & Z < 50 & la > 0; 'SH >50 m', ok & Z > 50 & la < 0; 'SH <50 m', ok & Z < 50 & la < 0};
rng(0);
res = zeros(7, 6);
for g = 1:7
    x = th(groups{g, 2}); y = ss(groups{g, 2});
    res(g, 1) = mean(x); res(g, 2:3) = bootci(10000, @mean, x)';
    res(g, 4) = mean(y); res(g, 5:6) = bootci(10000, @mean, y)';
end

fprintf('\nTheta'' trend per decade (x10, as plotted) and SST trend (degC/yr), mean [95%% CI]:\n');
fprintf('%-10s | %-28s | %-28s | %-24s | %-24s\n', 'group', 'theta'' AS RELEASED', 'theta'' CORRECTED', 'SST AS RELEASED', 'SST CORRECTED');
names = groups(:, 1);
tab = table();
for g = 1:7
    a = Wr.result(1:3, g); b = 10 * res(g, 1:3)'; c = Wr.result2(1:3, g); e = res(g, 4:6)';
    fprintf('%-10s | %+.4f [%+.4f %+.4f] | %+.4f [%+.4f %+.4f] | %+.4f [%+.4f %+.4f] | %+.4f [%+.4f %+.4f]\n', ...
        names{g}, a, b, c, e);
    tab = [tab; table(names(g), a(1), a(2), a(3), b(1), b(2), b(3), c(1), c(2), c(3), e(1), e(2), e(3), nnz(groups{g, 2}), ...
        'VariableNames', {'group', 'theta_rel', 'theta_rel_lo', 'theta_rel_hi', 'theta_cor', 'theta_cor_lo', ...
        'theta_cor_hi', 'sst_rel', 'sst_rel_lo', 'sst_rel_hi', 'sst_cor', 'sst_cor_lo', 'sst_cor_hi', 'n_corrected'})]; %#ok<AGROW>
end
writetable(tab, fullfile(out, 'fig4D_results.csv'));
fprintf('Saved fig4/outputs/fig4D_results.csv\n');
end

function finish(oldDir)
cd(oldDir);
diary off
end
