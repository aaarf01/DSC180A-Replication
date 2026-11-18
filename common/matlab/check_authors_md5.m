function check_authors_md5(root)
fprintf('\n--- Checking authors'' scripts against the v1.0.2 md5 list ---\n');
man = splitlines(strtrim(fileread(fullfile(root, 'authors_code', 'MD5_authors_v1.0.2.txt'))));
for k = 1:numel(man)
    parts = strsplit(strtrim(man{k}));
    h = md5_file(fullfile(root, 'authors_code', parts{2}));
    if ~strcmp(h, parts{1}), error('%s was modified (md5 %s, expected %s)', parts{2}, h, parts{1}); end
end
fprintf('All %d scripts match.\n', numel(man));
end
