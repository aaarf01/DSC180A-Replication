function rs = find_rscript()
% Locate Rscript. MATLAB on macOS does not inherit the Terminal PATH, so common
% install locations are checked explicitly. Returns '' if R is not found.
cands = {'/Library/Frameworks/R.framework/Resources/bin/Rscript', '/usr/local/bin/Rscript', ...
         '/opt/homebrew/bin/Rscript', '/usr/bin/Rscript'};
rs = '';
for k = 1:numel(cands)
    if exist(cands{k}, 'file'), rs = cands{k}; return; end
end
if ispc
    d = dir('C:\Program Files\R\R-*\bin\Rscript.exe');
    if ~isempty(d), rs = fullfile(d(end).folder, d(end).name); return; end
end
[st, out] = system('which Rscript');
if st == 0, rs = strtrim(out); end
end
