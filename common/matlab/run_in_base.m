function W = run_in_base(scriptFile, keep)
% Run a script in the base workspace (the authors' scripts start with 'clear'),
% then return its variables: all of them, or only those listed in keep.
% MATLAB's run() changes into the script's folder, so relative loads resolve there.
evalin('base', 'clear');
evalin('base', sprintf('run(''%s'');', strrep(scriptFile, '''', '''''')));
names = evalin('base', 'who');
if nargin > 1, names = intersect(names, keep); end
W = struct();
for k = 1:numel(names)
    W.(names{k}) = evalin('base', names{k});
end
evalin('base', 'clear');
end
