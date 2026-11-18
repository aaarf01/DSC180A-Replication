function dst = copy_verified(root, folder, name, runDir)
% Copy a script into the run folder and confirm the copy is byte-identical.
src = fullfile(root, folder, name);
dst = fullfile(runDir, name);
copyfile(src, dst);
assert(strcmp(md5_file(src), md5_file(dst)), 'Copy of %s differs from source', name);
end
