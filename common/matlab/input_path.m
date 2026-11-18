function [p, ok] = input_path(root, key)
% Full path of a catalogued input, and whether it exists.
C = input_catalog();
e = C(strcmp({C.key}, key));
assert(~isempty(e), 'Unknown input key %s', key);
p = fullfile(root, e.dest, e.file);
ok = exist(p, 'file') == 2;
end
