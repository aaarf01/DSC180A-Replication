function r = coord_check(name, map, landDisp, lon2, latd)
% (1) every Dryad land cell must be empty in the displayed map;
% (2) named landmarks must be land or ocean as expected.
emptyMap = ~isfinite(map);
r.landEmpty = mean(emptyMap(landDisp));
rot = circshift(emptyMap, 200, 2);
r.landEmptyIfShifted = mean(rot(landDisp));
lm = {'Congo basin', 0.5, 20.5, 1; 'Arabia', 25.5, 45.5, 1; 'Australia', -25.5, 134.5, 1; ...
      'USA', 35.5, -100.5, 1; 'Brazil', -10.5, -55.5, 1; 'Central Pacific', 0.5, -140.5, 0; ...
      'Indian Ocean', -20.5, 80.5, 0; 'North Atlantic', 25.5, -40.5, 0; ...
      'South Atlantic', -30.5, -10.5, 0; 'NW Pacific', 30.5, 160.5, 0};
ok = true(size(lm, 1), 1);
for k = 1:size(lm, 1)
    i = find(abs(latd - lm{k, 2}) < 1e-6);
    j = find(abs(mod(lon2, 360) - mod(lm{k, 3}, 360)) < 1e-6);
    ok(k) = emptyMap(i, j) == logical(lm{k, 4});
end
r.landmarksOK = all(ok);
fprintf('%s: Dryad land cells empty %.4f (%.4f if shifted 200 deg); landmarks correct %d/%d', ...
    name, r.landEmpty, r.landEmptyIfShifted, nnz(ok), numel(ok));
if all(ok), fprintf('\n'); else, fprintf(' -- WRONG: %s\n', strjoin(lm(~ok, 1)', ', ')); end
end
