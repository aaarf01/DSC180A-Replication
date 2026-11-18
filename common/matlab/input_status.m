function S = input_status(root, quiet)
% Report which catalogued inputs are present. Returns a struct of logicals.
if nargin < 2, quiet = false; end
C = input_catalog();
S = struct();
if ~quiet, fprintf('\n%-22s %-8s %-20s %s\n', 'input', 'status', 'needed for', 'source'); end
for k = 1:numel(C)
    [~, ok] = input_path(root, C(k).key);
    S.(C(k).key) = ok;
    if ~quiet
        st = 'ok'; if ~ok, st = 'MISSING'; end
        src = ''; if ~ok, src = C(k).source; end
        fprintf('%-22s %-8s %-20s %s\n', C(k).file, st, C(k).panels, src);
    end
end
end
