function run_fig1
% Fig. 1 of Martiny et al. (2026, Sci. Adv.): satellite theta' vs field measurements.
%   1A  theta' vs nutricline depth (published R = -0.52)   OUR reconstruction (MATLAB, this file)
%   1B  random forest R^2, nutricline vs +biomarkers         authors' R script, unchanged (fig1b.R)
%   1C  theta' by dominant stress type                       OUR reconstruction (fig1c.R)
%   1D  theta' vs nitrogen-use gene traits                   not reproducible (data not released)
% 1A needs data/thetaPrime_MODIS.mat and data/woa23_all_n00_01.nc. 1B and 1C need R and the
% CSVs already in data/. This runner calls R itself; you can also run the R scripts directly.
%   >> run_fig1          (from this folder, or via run_all at the repository root)

figDir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(figDir), 'common', 'matlab'));
if ~exist(fullfile(figDir, 'outputs'), 'dir'), mkdir(fullfile(figDir, 'outputs')); end
start_log(fullfile(figDir, 'outputs', 'fig1_run_log.txt'));
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
fprintf('=== Fig. 1 reproduction ===\n');
env = figure_env(figDir);
root = env.root; out = env.out;

%% 1B and 1C: R scripts
fprintf('\n=== Fig. 1B and 1C (R) ===\n');
rs = find_rscript();
if isempty(rs)
    fprintf('SKIPPED: Rscript not found. Install R (see README), or run in a terminal from the repository root:\n');
    fprintf('   Rscript fig1/fig1b.R\n   Rscript fig1/fig1c.R\n');
else
    fprintf('Rscript: %s\n', rs);
    for s = {'fig1b.R', 'fig1c.R'}
        fprintf('\nRunning %s (its own log is fig1/outputs/%s_run_log.txt) ...\n', s{1}, erase(s{1}, '.R'));
        [st, txt] = system(sprintf('"%s" "%s"', rs, fullfile(figDir, s{1})));
        lines = splitlines(strtrim(txt));
        fprintf('%s\n', strjoin(lines(max(1, end-25):end), newline));   % last lines of R output
        if st ~= 0, fprintf('R exited with status %d for %s; see its log.\n', st, s{1}); end
    end
end

%% 1A: theta' vs nutricline (MATLAB)
fprintf('\n=== Fig. 1A (OUR reconstruction) ===\n');
[fW, okW] = input_path(root, 'woa');
[~, okT] = input_path(root, 'theta');
[~, okI] = input_path(root, 'inpaint');
if ~okW || ~okT || ~okI
    fprintf(['SKIPPED: 1A needs data/thetaPrime_MODIS.mat, data/woa23_all_n00_01.nc and deps/inpaint_nans ' ...
             '(run setup_data; see README).\n']);
else
    fig1A(root, env.work, out, fW);
end

fprintf('\n=== Fig. 1D ===\n');
fprintf('NOT REPRODUCIBLE: needs per-gene trait abundances (table S1) from the raw metagenomes, which are not\n');
fprintf('in the released sample table.\n');
fprintf('\nTotal run time %.1f min\n', toc(tAll) / 60);
end

function fig1A(root, work, out, fW)
% The sample-level version (1,091 field samples) gives R = -0.43, P ~ 1e-50, but P < 1e-200 needs
% roughly 3,000+ points, so the published panel compares grid cells: satellite theta' against a
% WOA23 nutricline map. Three versions are reported.
require_functions({'geomean', 'smooth', 'inpaint_nans', 'corr', 'tcdf'});
G = prep_theta(root, work, out);
P = load(fullfile(work, 'DataLL_theta.mat'), 'DATAlowLat3');
Th = P.DATAlowLat3(:, [201:360 1:200], :); clear P           % display order (LON2 = 20.5:379.5)
LON2 = 20.5:379.5; LATb = G.LATband;
M = geomean(Th, 3, 'omitnan');                                 % same call as the authors' Fig. 2A script
[Zg, winfo] = woa_nutricline(fW, 3);
assert(isequal(winfo.lon, -179.5:179.5) && isequal(winfo.lat, -89.5:89.5), 'Unexpected WOA grid');
rows = arrayfun(@(la) find(winfo.lat == la), LATb);
Z = Zg(rows, [201:360 1:200]); Z(~isfinite(M)) = NaN;
fprintf('Nutricline: 3 umol/kg nitrate depth from WOA23 annual climatology, linear interpolation between\n');
fprintf('standard depths; surface >= 3 -> 0 m; never reaching 3 -> blank; masked to theta'' cells.\n');
chk = coord_check('Fig. 1A nutricline grid', Z, G.landDisp, LON2, LATb);

fprintf('\nThree versions (all ours):\n');
fprintf('  V1 geometric-mean theta'' (as Fig. 2A) vs nutricline, one point per grid cell\n');
fprintf('  V2 arithmetic time-mean theta'' vs nutricline, one point per grid cell\n');
fprintf('  V3 every 8-day theta'' value vs its cell''s nutricline\n');
V = {'V1 geometric mean', M; 'V2 arithmetic mean', mean(Th, 3)};
fprintf('\n%-22s %-38s %9s %8s %10s\n', 'version', 'subset', 'n', 'R', 'P');
res = {};
for k = 1:2
    y = V{k, 2};
    for s = 1:2
        ok = isfinite(y) & isfinite(Z); lab = 'all cells';
        if s == 2, ok = ok & Z <= 250 & y <= 4; lab = 'within plot axes (Z<=250, theta''<=4)'; end
        [r, p] = corr(Z(ok), y(ok));
        fprintf('%-22s %-38s %9d %+8.3f %10.2g\n', V{k, 1}, lab, nnz(ok), r, p);
        res(end+1, :) = {V{k, 1}, lab, nnz(ok), r, p}; %#ok<AGROW>
    end
end
Zr = repmat(Z, 1, 1, size(Th, 3));
for s = 1:2
    ok = isfinite(Th) & isfinite(Zr); lab = 'all values';
    if s == 2, ok = ok & Zr <= 250 & Th <= 4; lab = 'within plot axes (Z<=250, theta''<=4)'; end
    x = Zr(ok); y = Th(ok); n = numel(x);
    r = corr(x, y); t = r * sqrt((n - 2) / (1 - r^2)); p = 2 * tcdf(-abs(t), n - 2);
    fprintf('%-22s %-38s %9d %+8.3f %10.2g\n', 'V3 all 8-day values', lab, n, r, p);
    res(end+1, :) = {'V3 all 8-day values', lab, n, r, p}; %#ok<AGROW>
end
clear Zr
fprintf('Published: R = -0.52, P < 1e-200. A P of 0 means below double precision (< ~1e-308).\n');

edges = 0:25:250; ctr = edges(1:end-1) + 12.5;
pubX = [12 37 62 87 112 137 162 187 212 237];
pubY = [2.37 2.75 2.27 1.95 1.55 1.37 1.20 0.97 0.88 0.88];    % read from the published figure (approx.)
fprintf('\nBinned mean theta'' (25 m bins) vs the published red line (read from the figure, approx.):\n');
fprintf('%8s %10s %10s %10s\n', 'bin (m)', 'V1', 'V3', 'published');
okc = isfinite(M) & isfinite(Z);
bm1 = nan(size(ctr)); bm3 = nan(size(ctr));
for i = 1:numel(ctr)
    in = okc & Z >= edges(i) & Z < edges(i+1);
    bm1(i) = mean(M(in));
    t3 = Th(repmat(in, 1, 1, size(Th, 3))); bm3(i) = mean(t3(isfinite(t3)));
    fprintf('%8.1f %10.2f %10.2f %10.2f\n', ctr(i), bm1(i), bm3(i), pubY(i));
end
fprintf('Correlation of binned means with the published line: V1 %.2f, V3 %.2f\n', ...
    corr(bm1(:), pubY(:), 'rows', 'complete'), corr(bm3(:), pubY(:), 'rows', 'complete'));

f = figure('Color', 'w', 'Position', [100 100 520 460]);
N = histcounts2(M(okc), Z(okc), 0:0.1:4, 0:10:250);
imagesc([5 245], [0.05 3.95], N); axis xy
colormap([linspace(1, 0.13, 256)' linspace(1, 0.4, 256)' linspace(1, 0.7, 256)']); hold on
plot(ctr, bm1, 'r-o', 'LineWidth', 2.5, 'MarkerFaceColor', 'r');
plot(pubX, pubY, 'k--', 'LineWidth', 1);
xlabel('Nutricline (m)'); ylabel('Satellite (\Theta'')'); xlim([0 250]); ylim([0 4]);
title(sprintf('Fig. 1A reconstruction (V1): R = %.2f, n = %d', res{1, 4}, nnz(okc)));
legend({'binned mean (ours)', 'published line (approx.)'}, 'Location', 'northeast');
exportgraphics(f, fullfile(out, 'fig1a_reconstruction.png'), 'Resolution', 150);
savefig(f, fullfile(out, 'fig1a_reconstruction.fig')); close(f);

Tres = cell2table(res, 'VariableNames', {'version', 'subset', 'n', 'R', 'P'});
writetable(Tres, fullfile(out, 'fig1a_results.csv'));
save(fullfile(out, 'fig1a_results.mat'), 'Tres', 'ctr', 'bm1', 'bm3', 'pubX', 'pubY', 'chk', 'M', 'Z', 'LON2', 'LATb');
fprintf('Saved fig1a_results.csv, fig1a_results.mat and fig1a_reconstruction.png in fig1/outputs/\n');
end

function finish(oldDir)
cd(oldDir);
diary off
end
