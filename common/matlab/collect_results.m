function T = collect_results(root)
% Gather the key numbers from every figure's output files into one table,
% results_summary.csv at the repository root: figure, panel, quantity, our value,
% published value, and the file it came from. Figures that have not been run are left out.
rows = cell(0, 6);
o = @(f, name) fullfile(root, f, 'outputs', name);

% Fig. 1B
f = o('fig1', 'fig1b_results.csv');
if exist(f, 'file')
    t = readtable(f, 'TextType', 'string');
    pub = containers.Map({'n_final_models', 'oob_r2_nutricline', 'oob_r2_nutricline_plus_genes'}, ...
                         {'990', '~0.36 (bar)', '~0.62 (bar)'});
    lab = containers.Map({'n_final_models', 'oob_r2_nutricline', 'oob_r2_nutricline_plus_genes'}, ...
                         {'Samples in final models', 'OOB R2, nutricline only', 'OOB R2, nutricline + biomarkers'});
    for i = 1:height(t)
        q = char(t.quantity(i));
        if isKey(pub, q), rows(end+1, :) = {'1', '1B', lab(q), t.value(i), pub(q), 'fig1/outputs/fig1b_results.csv'}; end %#ok<AGROW>
    end
end
% Fig. 1C (our reconstruction)
f = o('fig1', 'fig1c_results.csv');
if exist(f, 'file')
    t = readtable(f, 'TextType', 'string');
    for i = 1:height(t)
        rows(end+1, :) = {'1', '1C (reconstruction)', "Theta' residual, dominant " + t.stress_type(i), ...
            t.C_main(i), sprintf('~%+.2f (read from figure)', t.published_approx(i)), 'fig1/outputs/fig1c_results.csv'}; %#ok<AGROW>
    end
end
% Fig. 1A (our reconstruction)
f = o('fig1', 'fig1a_results.csv');
if exist(f, 'file')
    t = readtable(f, 'TextType', 'string');
    for i = 1:height(t)
        if contains(t.subset(i), "all")
            rows(end+1, :) = {'1', '1A (reconstruction)', "R, " + t.version(i) + " (n = " + t.n(i) + ")", ...
                t.R(i), '-0.52', 'fig1/outputs/fig1a_results.csv'}; %#ok<AGROW>
        end
    end
end
% Figs. 2, 3, 4: summary tables already pair our value with the published one
specs = {'2', 'fig2', 'fig2_summary.csv'; '3', 'fig3', 'fig3_summary.csv'; '4', 'fig4', 'fig4_summary.csv'};
for s = 1:size(specs, 1)
    f = o(specs{s, 2}, specs{s, 3});
    if ~exist(f, 'file'), continue; end
    t = readtable(f, 'TextType', 'string');
    pubCol = t.Properties.VariableNames{3};      % 'published_or_expected' or 'published'
    for i = 1:height(t)
        rows(end+1, :) = {specs{s, 1}, '', string(t.quantity(i)), t.reproduced(i), string(t.(pubCol)(i)), ...
            [specs{s, 2} '/outputs/' specs{s, 3}]}; %#ok<AGROW>
    end
end
f = o('fig4', 'fig4D_results.csv');
if exist(f, 'file')
    t = readtable(f, 'TextType', 'string');
    for i = 1:height(t)
        rows(end+1, :) = {'4', '4D', "Theta' trend x10, " + t.group(i) + " (as released / corrected)", ...
            t.theta_rel(i), sprintf('corrected: %.4f', t.theta_cor(i)), 'fig4/outputs/fig4D_results.csv'}; %#ok<AGROW>
    end
end

rows(:, 3) = cellfun(@string, rows(:, 3), 'UniformOutput', false);   % uniform text columns
rows(:, 5) = cellfun(@string, rows(:, 5), 'UniformOutput', false);
T = cell2table(rows, 'VariableNames', {'figure', 'panel', 'quantity', 'reproduced', 'published', 'source'});
writetable(T, fullfile(root, 'results_summary.csv'));
end
