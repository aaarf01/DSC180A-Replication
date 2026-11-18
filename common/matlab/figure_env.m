function env = figure_env(figDir)
% Common start-up for a figure runner: folders, MATLAB path, version log,
% and the check that every authors' script in authors_code/ is unmodified.
env.fig = figDir;
env.root = fileparts(figDir);
env.out = fullfile(figDir, 'outputs');
env.work = fullfile(figDir, 'work');
for d = {env.out, env.work}
    if ~exist(d{1}, 'dir'), mkdir(d{1}); end
end
addpath(fullfile(env.root, 'common', 'matlab'));
addpath(genpath(fullfile(env.root, 'deps')));
fprintf('Run started: %s\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
fprintf('MATLAB %s\n', version);
v = ver;
for name = {'Statistics and Machine Learning Toolbox', 'Curve Fitting Toolbox', 'Signal Processing Toolbox'}
    k = find(strcmp({v.Name}, name{1}));
    if isempty(k), fprintf('  %s: not installed\n', name{1}); else, fprintf('  %s %s\n', v(k).Name, v(k).Version); end
end
fprintf('CDT: %s\n', strtrim(fileread(fullfile(env.root, 'deps', 'cdt', 'VERSION.txt'))));
fprintf('BrewerMap: %s\n', strtrim(fileread(fullfile(env.root, 'deps', 'colorbrewer', 'VERSION.txt'))));
check_authors_md5(env.root);
end
