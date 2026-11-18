function save_figs(tag, outDir)
% Save every open figure as PNG and .fig, then close them. A figure that cannot
% be saved is logged and skipped; saving is for inspection only.
drawnow;
figs = findall(groot, 'Type', 'figure');
figs = figs(isgraphics(figs));
if isempty(figs), return; end
num = arrayfun(@(f) double(min([f.Number, Inf])), figs);
[~, ord] = sort(num); figs = figs(ord);
for k = 1:numel(figs)
    base = fullfile(outDir, sprintf('%s_fig%d', tag, k));
    if ~isgraphics(figs(k))
        fprintf('  WARNING: figure %d of %s was closed before it could be saved; skipped\n', k, tag);
        continue
    end
    try
        exportgraphics(figs(k), [base '.png'], 'Resolution', 150);
        savefig(figs(k), [base '.fig']);
        fprintf('  saved %s.png\n', base);
    catch ME
        fprintf('  WARNING: could not save figure %d of %s (%s); skipped\n', k, tag, ME.message);
    end
end
close(figs(isgraphics(figs)));
end
