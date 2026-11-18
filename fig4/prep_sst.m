function prep_sst(fSST, yr, yd, thetaLand, LAT, LON, outFile)
% Build DataLL_SST.mat (saved to outFile). Fig. 4 only. The authors provide no SST preprocessing script, so this
% applies the same steps as their theta' preprocessing EXCEPT the 0-4 clipping.
fprintf('Reading %s (large file, may take a few minutes)...\n', fSST);
M = readmatrix(fSST, 'NumHeaderLines', 0);
fprintf('CSV size %s (expect 64802 x 899)\n', mat2str(size(M)));
yrS = M(1, 3:end)'; ydS = M(2, 3:end)';
if numel(yrS) ~= numel(yr) || any(yrS ~= yr) || any(ydS ~= yd)
    error('SST time axis does not match theta'' (%d vs %d steps). Stopping.', numel(yrS), numel(yr));
end
fprintf('SST time axis matches theta'' exactly (%d steps).\n', numel(yr));
c1 = M(3:end, 1); c2 = M(3:end, 2);
V = M(3:end, 3:end); clear M
nT = size(V, 2);
nR = size(V, 1);
assert(nR == 64800, 'Expected 64800 grid rows, found %d', nR);

% ---- A. What do the coordinate columns say? ------------------------------
% Test each column against the coordinates every candidate layout implies.
% Row k of a lat-fastest (column-major) layout is LAT(mod(k-1,180)+1), LON(floor((k-1)/180)+1);
% row k of a lon-fastest layout is LON(mod(k-1,360)+1), LAT(floor((k-1)/360)+1).
fprintf('\n-- A. Coordinate columns (col 1 should be latitude, col 2 longitude) --\n');
LAT = LAT(:); LON = LON(:); k = (0:nR-1)';
hyp = {'lat-fastest', LAT(mod(k,180)+1),  LON(floor(k/180)+1); ...
       'lon-fastest', LAT(floor(k/360)+1), LON(mod(k,360)+1)};
pairOK = false(2, 1);
for h = 1:2
    m1 = mean(abs(c1 - hyp{h, 2}) < 1e-6);
    m2 = mean(abs(c2 - hyp{h, 3}) < 1e-6);
    pairOK(h) = m1 == 1 && m2 == 1;
    fprintf('  %-12s col1 matches %.4f | col2 matches %.4f\n', hyp{h, 1}, m1, m2);
end
fprintf('  col1 distinct values %d (range %.1f to %.1f); col2 distinct values %d (range %.1f to %.1f)\n', ...
    numel(unique(c1)), min(c1), max(c1), numel(unique(c2)), min(c2), max(c2));
r1 = find(abs(c1 - c1(1)) < 1e-6, 2); r2 = find(abs(c2 - c2(1)) < 1e-6, 2);
if numel(r1) > 1, fprintf('  col1 first repeats after %d rows\n', r1(2) - 1); end
if numel(r2) > 1, fprintf('  col2 first repeats after %d rows\n', r2(2) - 1); end
if any(pairOK)
    fprintf('  Coordinate columns form consistent (lat, lon) pairs for: %s\n', hyp{pairOK, 1});
else
    fprintf('  FINDING: no layout makes BOTH columns correct row by row, so the coordinate\n');
    fprintf('  columns cannot serve as row labels on their own. Deciding with the data checks below.\n');
end

% ---- B. Checks on the data itself, for every candidate layout --------------
fprintf('\n-- B. Data checks per candidate layout --\n');
landV = all(isnan(V), 2);
meanV = mean(V, 2, 'omitnan');                       % time-mean SST per row
names = {'lat-fastest', 'lat-fastest, flipped', 'lon-fastest', 'lon-fastest, flipped'};
band = 50:131;                                        % 40.5N-40.5S, the analysis domain
cEq = 86:95; cHi = 21:30;                             % rows for 3.5N-5.5S and 69.5N-60.5N
colWP = 321:340; colCT = 71:90;                       % lon 140.5E-159.5E and 109.5W-90.5W
score = zeros(4, 1); pass = false(4, 1);
for c = 1:4
    L = layout_map(landV, c); S = layout_map(meanV, c);
    agBand = mean(L(band, :) == thetaLand(band, :), 'all');
    agAll  = mean(L(:) == thetaLand(:));
    eq = mean(S(cEq, :), 'all', 'omitnan'); hi = mean(S(cHi, :), 'all', 'omitnan');
    wp = mean(S(cEq, colWP), 'all', 'omitnan'); ct = mean(S(cEq, colCT), 'all', 'omitnan');
    pass(c) = eq > 25 && hi < 12 && (wp - ct) > 2;
    score(c) = agBand;
    fprintf('  %-22s land agree: global %.4f, 40S-40N %.4f | equator %.1f C, 60-70N %.1f C | W Pacific - E Pacific %.1f C | physical checks %s\n', ...
        names{c}, agAll, agBand, eq, hi, wp - ct, string(pass(c)));
end
% Decide on 40S-40N land agreement (a north-south flip can pass the temperature
% checks, but not the land mask); the winner must also pass the physical checks.
[best, kb] = max(score);
srt = sort(score, 'descend');
if ~pass(kb) || best < 0.95 || srt(1) - srt(2) < 0.05 || ...
        (any(pairOK) && ~strcmp(names{kb}, hyp{find(pairOK, 1), 1}))
    error(['SST layout still ambiguous (best 40S-40N agreement %.4f, next %.4f, physical checks %s). ' ...
           'Stopping; please send the log.'], srt(1), srt(2), string(pass(kb)));
end
fprintf('Using layout: %s (40S-40N land agreement %.4f; next best %.4f)\n', names{kb}, best, srt(2));
fprintf('NOTE: global agreement is lower than in the 40S-40N band because theta'' is also missing over\n');
fprintf('      sea ice and polar night, where SST is not; only 40S-40N enters Fig. 4.\n');
switch kb
    case 1, G = reshape(V, 180, 360, nT);
    case 2, G = flipud(reshape(V, 180, 360, nT));
    case 3, G = permute(reshape(V, 360, 180, nT), [2 1 3]);
    case 4, G = flipud(permute(reshape(V, 360, 180, nT), [2 1 3]));
end
clear V

% Same steps as the authors' theta' preprocessing, minus clipping. Longitude is
% kept in the original -180..180 order (no reordering), matching DataLL_theta.mat,
% because the trend script reorders both arrays itself.
DATA = G; clear G
DL = reshape(DATA(50:131, :, :), 29520, nT); clear DATA
C = sum(isnan(DL), 2);
DL(C > 224, :) = NaN;
C = sum(isnan(DL), 2);
ind = find(C < nT & C > 0);
for j = 1:numel(ind)
    DL(ind(j), :) = inpaint_nans(DL(ind(j), :), 1);
end
D = DL';
for i = 1:size(D, 2)
    if C(i) == nT
        D(:, i) = NaN;
    else
        D(:, i) = smooth(D(:, i), 5, 'lowess');
    end
end
DATAlowLat3 = reshape(D', [82, 360, nT]); %#ok<NASGU>
save(outFile, 'DATAlowLat3');
fprintf('ASSUMPTION: SST gets the same >25%%-missing rule, inpainting and 5-point lowess as theta'', without clipping.\n');
fprintf('SST cells kept: %d\n', nnz(~all(isnan(DATAlowLat3), 3)));
end

function A = layout_map(x, c)
% Map a 64800-element vector onto the 180 x 360 grid under candidate layout c.
switch c
    case 1, A = reshape(x, 180, 360);            % lat-fastest
    case 2, A = flipud(reshape(x, 180, 360));    % lat-fastest, flipped
    case 3, A = reshape(x, 360, 180)';           % lon-fastest
    case 4, A = flipud(reshape(x, 360, 180)');   % lon-fastest, flipped
end
end
