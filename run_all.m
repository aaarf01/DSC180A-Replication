function run_all(varargin)
% RUN_ALL  Reproduce every figure, then bundle all outputs into one zip file.
%
%   run_all                    runs fig1, fig2, fig3, fig4 in order
%   run_all('fig2', 'fig3')    runs only the figures named
%
% Each figure runs in its own folder (figN/), writes its log and results to figN/outputs/,
% and catches its own errors, so one failure does not stop the others. A figure whose
% required inputs are missing is skipped with a message (run setup_data first).
% At the end, the key numbers from every figure are gathered into results_summary.csv
% (our value next to the published one), and the logs, tables and images in figN/outputs/
% plus that table are zipped into results_<date-time>.zip at the repository root (small
% enough to share; the .fig and .mat files stay in figN/outputs/).

root = fileparts(mfilename('fullpath'));
figs = {'fig1', 'fig2', 'fig3', 'fig4'};
if nargin, figs = intersect(figs, varargin, 'stable'); end
assert(~isempty(figs), 'Unknown figure name(s). Use fig1, fig2, fig3 or fig4.');
addpath(fullfile(root, 'common', 'matlab'));
t0 = tic;
fprintf('Repository: %s\n', root);
fprintf('Input files:');
S = input_status(root);
need.fig1 = true;                                   % 1B/1C need only the CSVs in data/; 1A is skipped inside if needed
need.fig2 = S.theta && S.inpaint;
need.fig3 = S.theta && S.oni && S.pdo && S.inpaint;
need.fig4 = S.theta && S.sst && S.inpaint;

status = cell(size(figs));
for k = 1:numel(figs)
    f = figs{k};
    fprintf('\n==================== %s ====================\n', upper(f));
    if ~need.(f)
        status{k} = 'skipped: inputs missing (run setup_data)';
        fprintf('Skipped: required input files are missing. Run setup_data, then run_all(''%s'').\n', f);
        continue
    end
    restoredefaultpath;                             % no leftovers from the previous figure
    addpath(fullfile(root, 'common', 'matlab'));
    close all force
    cd(fullfile(root, f));
    tf = tic;
    feval(['run_' f]);                              % each runner logs and catches its own errors
    cd(root);
    logf = fullfile(root, f, 'outputs', [f '_run_log.txt']);
    txt = ''; if exist(logf, 'file'), txt = fileread(logf); end
    if contains(txt, 'RUN FAILED')
        status{k} = sprintf('FAILED (see %s/outputs/%s_run_log.txt)', f, f);
    elseif contains(txt, 'SKIPPED')
        status{k} = sprintf('done, some panels skipped (%.1f min; see log)', toc(tf) / 60);
    else
        status{k} = sprintf('done (%.1f min)', toc(tf) / 60);
    end
end
cd(root);
restoredefaultpath; addpath(fullfile(root, 'common', 'matlab'));

% Write the summary, then bundle all outputs
summ = sprintf('run_all summary, %s\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
for k = 1:numel(figs), summ = [summ sprintf('%-6s %s\n', figs{k}, status{k})]; end %#ok<AGROW>
fid = fopen(fullfile(root, 'run_all_summary.txt'), 'w'); fprintf(fid, '%s', summ); fclose(fid);
Tres = collect_results(root);                     % one table of every reproduced number
fprintf('\nMaster results table (%d rows): %s\n', height(Tres), fullfile(root, 'results_summary.csv'));
disp(Tres(:, {'figure', 'panel', 'quantity', 'reproduced', 'published'}))
files = {fullfile(root, 'run_all_summary.txt'), fullfile(root, 'results_summary.csv')};
allFigs = {'fig1', 'fig2', 'fig3', 'fig4'};           % bundle every figure's latest outputs
for k = 1:numel(allFigs)
    d = dir(fullfile(root, allFigs{k}, 'outputs', '*'));
    d = d(~[d.isdir]);
    [~, ~, ext] = fileparts({d.name});
    d = d(ismember(lower(ext), {'.txt', '.csv', '.png', '.pdf'}));   % keep the zip small enough to share
    files = [files, fullfile({d.folder}, {d.name})]; %#ok<AGROW>
end
zipName = '';
if ~isempty(files)
    zipName = fullfile(root, ['results_' char(datetime('now', 'Format', 'yyyyMMdd_HHmm')) '.zip']);
    rel = erase(files, [root filesep]);
    zip(zipName, rel, root);
end

fprintf('\n==================== SUMMARY ====================\n');
for k = 1:numel(figs), fprintf('%-6s %s\n', figs{k}, status{k}); end
if ~isempty(zipName), fprintf('\nAll outputs bundled in: %s\n', zipName); end
fprintf('Total time %.1f min\n', toc(t0) / 60);
end
