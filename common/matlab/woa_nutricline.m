function [Z, info] = woa_nutricline(ncfile, thr)
% Nutricline depth (m) from a World Ocean Atlas 2023 nitrate climatology file:
% the depth where nitrate first reaches thr (umol/kg) going down from the surface,
% by linear interpolation between standard depths (the method the paper states for
% its CTD profiles).
% Choices for points the paper does not specify (logged by the caller):
%   * surface value already >= thr          -> Z = 0 m (nutricline at the surface)
%   * profile never reaches thr             -> Z = NaN
%   * missing levels: the profile is used down to its first missing level
% Returns Z on the WOA grid as lat x lon (180 x 360), lat ascending, lon -179.5..179.5.
if nargin < 2, thr = 3; end
lon = double(ncread(ncfile, 'lon')); lat = double(ncread(ncfile, 'lat'));
dep = double(ncread(ncfile, 'depth'));
N = double(ncread(ncfile, 'n_an'));            % lon x lat x depth (x time)
N = N(:, :, :, 1);
nx = numel(lon); ny = numel(lat);
Z = nan(nx, ny);
nSurf = 0; nNever = 0; nProf = 0;
for i = 1:nx
    for j = 1:ny
        v = squeeze(N(i, j, :));
        last = find(isnan(v), 1) - 1;
        if isempty(last), last = numel(v); end
        if last < 1, continue; end
        nProf = nProf + 1;
        v = v(1:last); d = dep(1:last);
        if v(1) >= thr, Z(i, j) = 0; nSurf = nSurf + 1; continue; end
        k = find(v >= thr, 1);
        if isempty(k), nNever = nNever + 1; continue; end
        Z(i, j) = d(k-1) + (thr - v(k-1)) * (d(k) - d(k-1)) / (v(k) - v(k-1));
    end
end
Z = Z';                                         % lat x lon
info.lat = lat(:)'; info.lon = lon(:)'; info.depth = dep(:)';
info.nProfiles = nProf; info.nSurfaceAbove = nSurf; info.nNeverReaches = nNever;
info.units = ncreadatt(ncfile, 'n_an', 'units');
end
