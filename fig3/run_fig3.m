function run_fig3
% Fig. 3 of Martiny et al. (2026, Sci. Adv.): theta' variability and climate cycles.
%   3A  PC5 vs ONI (published R = 0.81, P < 1e-216)       authors' code
%   3B  2011 anomaly map, 3C 2015 anomaly map             authors' code (ANOVA_yearly.m)
%   3D  PC6 vs PDO (published R = 0.59, P < 1e-85)        authors' code
%   3E  mean anomaly, PDO cool years 2007-14 and 2020-21  OUR reconstruction (no script released)
%   3F  mean anomaly, PDO warm years 2002-06 and 2015-19  OUR reconstruction (no script released)
% Needs: data/thetaPrime_MODIS.mat, data/oni.ascii.txt, data/ersst.v5.pdo.dat
%   >> run_fig3          (from this folder, or via run_all at the repository root)

figDir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(figDir), 'common', 'matlab'));
if ~exist(fullfile(figDir, 'outputs'), 'dir'), mkdir(fullfile(figDir, 'outputs')); end
start_log(fullfile(figDir, 'outputs', 'fig3_run_log.txt'));
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
fprintf('=== Fig. 3 reproduction ===\n');
env = figure_env(figDir);
root = env.root; work = env.work; out = env.out;
hasSPT = license('test', 'signal_toolbox') && ~isempty(ver('signal'));
if ~hasSPT
    addpath(fullfile(root, 'common', 'shims', 'plotpsd_standin'), '-begin');
    fprintf('DEVIATION: Signal Processing Toolbox not available; CDT''s plotpsd replaced by an FFT\n');
    fprintf('           periodogram stand-in (common/shims/plotpsd_standin). Affects only the spectrum panels.\n');
end
require_functions({'anovan', 'smooth', 'corr', 'inpaint_nans', 'cmocean', 'imagescn', 'clim', 'detrend3', 'eof', 'plotpsd'});
[~, ok] = input_path(root, 'theta');
if ~ok, error('data/thetaPrime_MODIS.mat not found. Run setup_data first (see README).'); end
% Locate the index files before the long steps, so a missing file stops the run early
fONI = find_index_file(fullfile(root, 'data'), 'oni');
fPDO = find_index_file(fullfile(root, 'data'), 'pdo');
fprintf('ONI file: %s\nPDO file: %s\n', fONI, fPDO);

%% Step P: preprocessing (shared code, identical for every figure)
G = prep_theta(root, work, out);

%% Step Y: 20 year levels, as in the paper
fprintf('\n=== Step Y: year levels for the ANOVA ===\n');
T = load(fullfile(work, 'time.mat'));
n22 = T.time_vec(:, 1) == 2022;
T.time_vec(n22, 1) = 2021;
time_vec = T.time_vec; timenum = T.timenum; time = T.time; %#ok<NASGU>
save(fullfile(work, 'time.mat'), 'time_vec', 'timenum', 'time');
fprintf('DEVIATION: the %d composite(s) dated 2022 (1 Jan 2022) counted as year 2021 in time_vec,\n', nnz(n22));
fprintf('           giving 20 year levels as in the paper. ANOVA_yearly.m fails with 21 levels (it labels\n');
fprintf('           panels 2002:2021). timenum and time are unchanged, so EOF and index steps are unaffected.\n');
fprintf('           In the Fig. 2 analysis this changed monthly anomalies by at most 0.031.\n');

%% Step 1: ANOVA (one-line preallocation fix, same fix as in fig2/)
fprintf('\n=== Step 1: ANOVA_analysis (one-line preallocation fix) ===\n'); t = tic;
W = run_in_base(copy_verified(root, fullfile('common', 'patches'), 'ANOVA_analysis_PREALLOC.m', work), {'Coefs', 'ind'});
fprintf('ANOVA cells: %d; coefficients per cell: %d (expected 33 = 1 + 20 years + 12 months)\n', ...
    size(W.Coefs, 1), size(W.Coefs, 2));
assert(size(W.Coefs, 2) == 33, 'Unexpected number of ANOVA coefficients');
clear W
fprintf('Step 1 done (%.1f min)\n', toc(t) / 60);

%% Step 2: yearly anomalies (unchanged) -> Fig. 3B, 3C and fig. S14
fprintf('\n=== Step 2: ANOVA_yearly (unchanged) -> yearly anomaly maps ===\n'); t = tic;
W = run_in_base(copy_verified(root, 'authors_code', 'ANOVA_yearly.m', work), {'Annual', 'LAT', 'LON2'});
save_figs('step2_yearly_S14', out);
Annual = W.Annual; LON2 = W.LON2; LATb = W.LAT;
years = 2002:2021;
assert(size(Annual, 3) == numel(years), 'Expected 20 yearly maps, found %d', size(Annual, 3));
fprintf('Annual %s (lat x lon x year, 2002..2021)\n', mat2str(size(Annual)));
fprintf('Step 2 done (%.0f s)\n', toc(t));

%% Step 3: EOF analysis (unchanged)
fprintf('\n=== Step 3: EOF_variance (unchanged) ===\n'); t = tic;
W = run_in_base(copy_verified(root, 'authors_code', 'EOF_variance.m', work), ...
    {'eof_maps', 'pc', 'expv', 'Sexpv1_8', 'Sexpv4', 'Sexpv8'});
save_figs('step3_EOF', out);
E = W;
fprintf('Variance explained by EOFs 1-8 (%%): %s\n', mat2str(round(E.expv(1:8), 2)));
fprintf('Step 3 done (%.0f s)\n', toc(t));

%% Step 4: NOAA indices -> ONI.mat and PDO.mat in the authors' layout
fprintf('\n=== Step 4: NOAA climate indices (OURS: format conversion only) ===\n');
[ONI, iO] = read_noaa_index(fONI); %#ok<ASGLU>
[PDO, iP] = read_noaa_index(fPDO); %#ok<ASGLU>
save(fullfile(work, 'ONI.mat'), 'ONI'); save(fullfile(work, 'PDO.mat'), 'PDO');
fprintf('ONI: %s; %d months, %d-%02d to %d-%02d; range %.2f to %.2f\n', iO.format, iO.n, iO.first, iO.last, iO.range);
fprintf('PDO: %s; %d months, %d-%02d to %d-%02d; range %.2f to %.2f\n', iP.format, iP.n, iP.first, iP.last, iP.range);
fprintf('Saved as [value year month], the layout climate_index_comparison.m expects.\n');
for c = {{'ONI', ONI}, {'PDO', PDO}}
    X = c{1}{2}; tt = X(:, 2) + X(:, 3) / 12;
    if tt(1) > T.time(1) || tt(end) < T.time(end)
        fprintf('WARNING: %s covers %.3f-%.3f but theta'' spans %.3f-%.3f; interpolation gives NaN outside.\n', ...
            c{1}{1}, tt(1), tt(end), T.time(1), T.time(end));
    end
end

%% Step 5: index comparison (unchanged) -> Fig. 3A, 3D
fprintf('\n=== Step 5: climate_index_comparison (unchanged) -> Fig. 3A, 3D ===\n'); t = tic;
copyfile(fullfile(root, 'common', 'shims', 'inferno_cmap.mat'), fullfile(work, 'inferno_cmap.mat'));
W = run_in_base(copy_verified(root, 'authors_code', 'climate_index_comparison.m', work), {'R', 'P', 'YY', 'vq', 'time'});
save_figs('step5_index_comparison', out);
C = W;
fprintf('Rows PC5..PC8 (smoothed, 30-point lowess), columns ONI, PDO:\nR =\n'); disp(C.R);
fprintf('P =\n'); disp(C.P);
fprintf('Missing interpolated index values: ONI %d, PDO %d (of %d)\n', nnz(isnan(C.vq(:, 1))), nnz(isnan(C.vq(:, 2))), size(C.vq, 1));
fprintf('PC5 vs ONI: R = %+.3f, P = %.2g   (published |R| = 0.81, P < 1e-216; the authors plot -PC5,\n', C.R(1, 1), C.P(1, 1));
fprintf('            and EOF signs are arbitrary, so compare |R|)\n');
fprintf('PC6 vs PDO: R = %+.3f, P = %.2g   (published R = 0.59, P < 1e-85)\n', C.R(2, 2), C.P(2, 2));
fprintf('Step 5 done (%.0f s)\n', toc(t));

%% Step 6: mode-order and smoothing checks (ours)
fprintf('\n=== Step 6: which modes track ONI and PDO; smoothing sensitivity (OURS) ===\n');
fprintf('EOF modes can swap order or sign with small data differences, so every PC is tested.\n');
fprintf('Smoothing: code uses a 30-point lowess window; the paper''s methods say 20.\n');
tm = C.time(:); ok = all(isfinite(C.vq), 2);
fprintf('%4s %7s | %18s | %18s | %18s\n', 'PC', 'expv%', 'R ONI (30/20/raw)', 'R PDO (30/20/raw)', '');
Rall = zeros(8, 6);
for k = 1:8
    p = E.pc(k, :)';
    s30 = smooth(p, 30, 'lowess'); s20 = smooth(p, 20, 'lowess');
    Rall(k, :) = [corr(s30(ok), C.vq(ok, 1)) corr(s20(ok), C.vq(ok, 1)) corr(p(ok), C.vq(ok, 1)) ...
                  corr(s30(ok), C.vq(ok, 2)) corr(s20(ok), C.vq(ok, 2)) corr(p(ok), C.vq(ok, 2))];
    fprintf('%4d %7.2f | %+5.2f %+5.2f %+5.2f | %+5.2f %+5.2f %+5.2f\n', k, E.expv(k), Rall(k, :));
end
[~, bO] = max(abs(Rall(:, 1))); [~, bP] = max(abs(Rall(:, 4)));
fprintf('Mode most correlated with ONI: PC%d (paper: PC5). With PDO: PC%d (paper: PC6).\n', bO, bP);
s20 = smooth(E.pc(5, :)', 20, 'lowess'); s20b = smooth(E.pc(6, :)', 20, 'lowess');
[r20o, p20o] = corr(s20(ok), C.vq(ok, 1)); [r20p, p20p] = corr(s20b(ok), C.vq(ok, 2));
fprintf('With the paper''s 20-point window: PC5-ONI R = %+.3f (P = %.2g); PC6-PDO R = %+.3f (P = %.2g)\n', r20o, p20o, r20p, p20p);
% Time check: the theta' time axis (decimal years) and the index times use different conventions
fprintf('Time conventions: theta'' time = yr + yd/365 (start of composite); index time = year + month/12.\n');

%% Step 7: Fig. 3B, C, E, F maps (B, C from the authors' output; E, F our reconstruction)
fprintf('\n=== Step 7: Fig. 3B, 3C, 3E, 3F maps ===\n');
cool = [2007:2014 2020:2021]; warm = [2002:2006 2015:2019];
Mcool = mean(Annual(:, :, ismember(years, cool)), 3);
Mwarm = mean(Annual(:, :, ismember(years, warm)), 3);
fprintf('RECONSTRUCTION: 3E = mean of the yearly anomaly maps for %s;\n', mat2str(cool));
fprintf('                3F = same for %s (years from the caption). No script was released.\n', mat2str(warm));
fprintf('Note: 2002 starts in July and "2021" includes the 1 Jan 2022 composite.\n');
f = figure('Color', 'w', 'Position', [100 100 1100 560]);
maps = {Annual(:, :, years == 2011), Annual(:, :, years == 2015), Mcool, Mwarm};
ttl = {'B: 2011 (La Nina)', 'C: 2015 (El Nino)', 'E: PDO cool phase (reconstruction)', 'F: PDO warm phase (reconstruction)'};
for p = 1:4
    subplot(2, 2, p);
    imagescn(LON2, LATb, maps{p}); clim([-0.8 0.8]); cmocean('balance'); colorbar
    xticks([90 180 270 360]); xticklabels({'90E', '180E', '90W', '0'}); title(ttl{p});
end
sgtitle('Fig. 3 maps: \Theta'' anomaly (scale \pm0.8 as published; the authors'' script uses \pm1)');
exportgraphics(f, fullfile(out, 'step7_fig3_maps.png'), 'Resolution', 150);
savefig(f, fullfile(out, 'step7_fig3_maps.fig')); close(f);
for p = 1:4
    x = maps{p}(isfinite(maps{p}));
    fprintf('  %-36s median %+.3f, 1st-99th pct %+.2f to %+.2f, beyond +/-0.8: %.1f%%\n', ttl{p}, ...
        median(x), prctile(x, 1), prctile(x, 99), 100 * mean(abs(x) > 0.8));
end

% Our version of panels A and D with the published sign convention (authors plot -PC5)
f = figure('Color', 'w', 'Position', [100 100 1000 650]);
idx = {1, 2}; nm = {'ONI', 'PDO'}; pcn = [5 6]; sgn = [-1 1]; pubR = {'0.81', '0.59'};
for p = 1:2
    subplot(2, 1, p);
    yyaxis left; plot(tm, sgn(p) * C.YY(:, idx{p}), '-'); ylim([-25 25]); ylabel(sprintf('%sPC%d', repmat('-', 1, sgn(p) < 0), pcn(p)));
    yyaxis right; plot(tm, C.vq(:, idx{p}), '-'); ylim([-2.8 2.8]); ylabel(nm{p});
    xlim([2002 2022]); grid on
    title(sprintf('%s: PC%d vs %s, R = %.2f (published %s)', char('A' + 3 * (p - 1)), pcn(p), nm{p}, ...
        sgn(p) * C.R(p, p), pubR{p}));
end
exportgraphics(f, fullfile(out, 'step7_fig3_AD.png'), 'Resolution', 150);
savefig(f, fullfile(out, 'step7_fig3_AD.fig')); close(f);
fprintf('NOTE: in our A/D figure the index is shown at the theta'' time points (interpolated, as\n');
fprintf('      correlated); the published figure plots the PDO with an extra 10-point loess for display.\n');

%% Step 8: coordinate checks
fprintf('\n=== Step 8: coordinate checks (OURS) ===\n');
expLon = mod([G.LONg(201:360) G.LONg(1:200)], 360);
fprintf('Display longitudes equal the reordered Dryad longitudes: %s\n', string(isequal(mod(LON2, 360), expLon)));
fprintf('Display latitudes 40.5N..40.5S: %s\n', string(isequal(LATb(:)', G.LATband)));
chk.y2011 = coord_check('Fig. 3B 2011 anomaly', maps{1}, G.landDisp, LON2, G.LATband);
chk.eof5  = coord_check('EOF 5 loading map', E.eof_maps(:, :, 5), G.landDisp, LON2, G.LATband);

%% Summary
fprintf('\n=== Summary ===\n');
q = {'|R| PC5 vs ONI (30-pt smoothing, code)'; 'P PC5 vs ONI'; '|R| PC6 vs PDO (30-pt smoothing, code)'; ...
     'P PC6 vs PDO'; '|R| PC5 vs ONI (20-pt, paper text)'; '|R| PC6 vs PDO (20-pt, paper text)'; ...
     'Mode most correlated with ONI'; 'Mode most correlated with PDO'; ...
     'Variance explained PC5 (%)'; 'Variance explained PC6 (%)'; 'Year levels in ANOVA'; 'ANOVA cells'; ...
     'Fig. 3B land cells correctly empty'};
ours = [abs(C.R(1, 1)); C.P(1, 1); abs(C.R(2, 2)); C.P(2, 2); abs(r20o); abs(r20p); bO; bP; ...
        E.expv(5); E.expv(6); 20; G.nCells; chk.y2011.landEmpty];
pub = {'0.81'; '< 1e-216'; '0.59'; '< 1e-85'; '0.81'; '0.59'; '5'; '6'; 'not stated'; 'not stated'; ...
       '20'; '20822'; '1 expected'};
Tsum = table(q, ours, pub, 'VariableNames', {'quantity', 'reproduced', 'published_or_expected'});
disp(Tsum)
writetable(Tsum, fullfile(out, 'fig3_summary.csv'));
pc = E.pc; expv = E.expv; eof_maps = E.eof_maps; R = C.R; P = C.P; YY = C.YY; vq = C.vq; time = tm; %#ok<NASGU>
save(fullfile(out, 'fig3_results.mat'), 'Annual', 'years', 'Mcool', 'Mwarm', 'LON2', 'LATb', ...
     'pc', 'expv', 'eof_maps', 'R', 'P', 'YY', 'vq', 'time', 'Rall', 'chk');
fprintf('Saved fig3_summary.csv and fig3_results.mat in outputs/\n');
fprintf('Total run time %.1f min\n', toc(tAll) / 60);
end

%% ------------------------------------------------------------------ helpers
function f = find_index_file(dataDir, key)
d = dir(dataDir);
names = {d(~[d.isdir]).name};
hit = names(contains(lower(names), key) & ~endsWith(lower(names), '.mat'));
if isempty(hit)
    error(['No %s file found in data/. Download it from NOAA (see README) and put it in data/ ' ...
           'with "%s" in the file name, or run setup_data.'], upper(key), key);
end
if numel(hit) > 1, error('Several %s files in data/: %s. Keep one.', upper(key), strjoin(hit, ', ')); end
f = fullfile(dataDir, hit{1});
end

function finish(oldDir)
cd(oldDir);
diary off
end
