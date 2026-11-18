function setup_data(searchRoot)
% SETUP_DATA  Find the input files on this computer and copy them into place.
%
%   setup_data                 searches the folder that CONTAINS this repository
%                              (e.g. the folder holding your older replication kits)
%   setup_data('/some/folder') searches that folder and everything inside it
%
% It looks for every file listed in common/matlab/input_catalog.m, copies data files
% into data/ and the inpaint_nans folder into deps/inpaint_nans, skips anything already
% in place, and finally prints what is still missing with a download link for each.
% Nothing outside this repository is changed or moved.

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'common', 'matlab'));
if nargin < 1, searchRoot = fileparts(root); end
searchRoot = char(searchRoot);
assert(isfolder(searchRoot), 'Folder not found: %s', searchRoot);
fprintf('Searching %s (and all subfolders) for the input files...\n\n', searchRoot);

C = input_catalog();
for k = 1:numel(C)
    e = C(k);
    [dest, ok] = input_path(root, e.key);
    if ok, fprintf('%-22s already in place\n', e.file); continue; end
    % Browsers often save text downloads with an extra .txt (e.g. ersst.v5.pdo.dat.txt): fix that
    if ~strcmp(e.key, 'inpaint') && exist([dest '.txt'], 'file')
        movefile([dest '.txt'], dest);
        fprintf('%-22s renamed %s.txt -> %s\n', e.file, e.file, e.file);
        continue
    end
    hits = dir(fullfile(searchRoot, '**', e.file));
    if isempty(hits) && ~strcmp(e.key, 'inpaint')
        hits = dir(fullfile(searchRoot, '**', [e.file '.txt']));   % same file, saved with .txt added
    end
    hits = hits(~[hits.isdir]);
    inRepo = startsWith({hits.folder}, root);           % never copy from inside this repository
    hits = hits(~inRepo);
    if strcmp(e.key, 'inpaint')
        % The Climate Data Toolbox keeps its own internal copy in cdt/.../private; never use that
        bad = contains({hits.folder}, [filesep 'private']) | contains({hits.folder}, [filesep 'cdt']);
        hits = hits(~bad);
    end
    if isempty(hits), fprintf('%-22s not found\n', e.file); continue; end
    [~, i] = max([hits.bytes]);                           % if several copies, take the largest
    src = fullfile(hits(i).folder, hits(i).name);
    if numel(hits) > 1, fprintf('%-22s %d copies found; using the largest\n', e.file, numel(hits)); end
    if ~exist(fileparts(dest), 'dir'), mkdir(fileparts(dest)); end
    if strcmp(e.key, 'inpaint')
        copyfile(fullfile(hits(i).folder, '*'), fileparts(dest));   % the whole folder, incl. its licence
        fprintf('%-22s copied folder %s -> deps/inpaint_nans/\n', e.file, hits(i).folder);
    else
        fprintf('%-22s copying %s (%.0f MB) ...', e.file, src, hits(i).bytes / 1e6);
        copyfile(src, dest);
        fprintf(' done\n');
    end
end

fprintf('\nStatus:');
S = input_status(root);
fprintf('\nWhat can run:\n');
fprintf('  fig1: 1B and 1C always (need R); 1A needs thetaPrime_MODIS.mat + woa23_all_n00_01.nc -> %s\n', yesno(S.theta && S.woa && S.inpaint));
fprintf('  fig2: needs thetaPrime_MODIS.mat (2B also woa23) -> %s\n', yesno(S.theta && S.inpaint));
fprintf('  fig3: needs thetaPrime_MODIS.mat + oni.ascii.txt + ersst.v5.pdo.dat -> %s\n', yesno(S.theta && S.oni && S.pdo && S.inpaint));
fprintf('  fig4: needs thetaPrime_MODIS.mat + SST_v2_25-04.csv (4D also Dataset S1_WOD.csv) -> %s\n', yesno(S.theta && S.sst && S.inpaint));
fprintf('\nFor anything MISSING, download it from the link shown, put it in data/ (or deps/inpaint_nans/),\n');
fprintf('or run setup_data again with the folder where it is: setup_data(''/path/to/folder'')\n');
end

function s = yesno(tf)
if tf, s = 'ready'; else, s = 'NOT ready'; end
end
