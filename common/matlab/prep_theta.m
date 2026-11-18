function G = prep_theta(root, runDir, outDir)
% Theta' preprocessing shared by every figure (1A, 2, 3, 4), run inside that figure's work/ folder:
% Dryad theta' -> authors' prepare_time_files.m (unchanged) and
% preprocess_LowLat_thetaPrime_v3_bathy.m (path-only patch) -> work/DataLL_theta.mat
% saved in the original -180..180 longitude order, which the ANOVA/EOF scripts expect.
% Returns grid info and the Dryad land mask for coordinate checks.
fprintf('\n=== Step P: theta'' preprocessing (shared by every figure) ===\n'); t = tic;
for d = {fullfile(runDir, 'cdt'), fullfile(runDir, 'colorbrewer'), fullfile(runDir, 'Inpaint_nans'), fullfile(runDir, 'ddd2mmdd')}
    if ~exist(d{1}, 'dir'), mkdir(d{1}); end
end
copyfile(fullfile(root, 'common', 'shims', 'ddd2mmdd.m'), fullfile(runDir, 'ddd2mmdd', 'ddd2mmdd.m'));
fTheta = fullfile(root, 'data', 'thetaPrime_MODIS.mat');
assert(exist(fTheta, 'file') == 2, 'Missing data/thetaPrime_MODIS.mat');
S = load(fTheta);
yr = S.yr; yd = S.yd; LAT = S.LAT; LON = S.LON; %#ok<NASGU>
fprintf('Theta'' grid %s; first %d/%03d; last %d/%03d\n', mat2str(size(S.thetaprime_MODIS)), yr(1), yd(1), yr(end), yd(end));
save(fullfile(runDir, 'thPrime_1degree_032223.mat'), 'yr', 'yd');
thetaprime2 = S.thetaprime_MODIS; %#ok<NASGU>
save(fullfile(runDir, 'thetaPrime_Dec24.mat'), 'thetaprime2'); clear thetaprime2
G.landG = all(isnan(S.thetaprime_MODIS), 3);   % Dryad land mask, original order
G.LATg = S.LAT(:)'; G.LONg = S.LON(:)'; clear S
bathyLL = true(82, 360); %#ok<NASGU>
save(fullfile(runDir, 'BathyLL.mat'), 'bathyLL');
fprintf('DEVIATION: BathyLL.mat is not released; all-true mask used (paper''s ANOVA n = 20,822 vs ~22,468 here).\n');
run_in_base(copy_verified(root, 'authors_code', 'prepare_time_files.m', runDir), {});
fprintf('prepare_time_files.m (unchanged) done; ddd2mmdd stand-in from shims/.\n');
W = run_in_base(copy_verified(root, fullfile('common', 'patches'), 'preprocess_LowLat_thetaPrime_v3_bathy_PATHS.m', runDir), {'DATAlowLat3'});
save_figs('stepP_preprocess', outDir);
S3 = W.DATAlowLat3; clear W
DATAlowLat3 = [S3(:, 161:360, :) S3(:, 1:160, :)]; clear S3
save(fullfile(runDir, 'DataLL_theta.mat'), 'DATAlowLat3', 'LAT', 'LON');
fprintf('preprocess_..._bathy (path-only patch) done; DataLL_theta.mat saved in original -180..180 order.\n');

% Order check against the Dryad land mask
landBand = G.landG(50:131, :);
kept = ~all(isnan(DATAlowLat3), 3);
okOrig = mean(~kept(landBand));
keptRot = kept(:, [201:360 1:200]);
okRot = mean(~keptRot(landBand));
fprintf('Dryad land cells empty in DataLL_theta.mat: %.4f as stored, %.4f if reordered\n', okOrig, okRot);
if okOrig < 0.999 || okOrig - okRot < 0.2
    error('DataLL_theta.mat is not in the expected original -180..180 longitude order.');
end
G.nCells = nnz(kept);
G.landDisp = landBand(:, [201:360 1:200]);       % land mask in display order (LON2 = 20.5:379.5)
G.LATband = G.LATg(50:131);
fprintf('Order confirmed. Cells with data: %d (earlier runs: 22468)\n', G.nCells);
fprintf('Step P done (%.0f s)\n', toc(t));
end
