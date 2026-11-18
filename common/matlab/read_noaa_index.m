function [X, info] = read_noaa_index(file)
% Read a NOAA monthly climate-index text file into the layout the authors'
% climate_index_comparison.m expects: X = [value year month], one row per month.
% Supported layouts (detected automatically):
%   * CPC ONI table (oni.ascii.txt): header "SEAS YR TOTAL ANOM"; rows "DJF 1950 24.72 -1.53".
%     The 3-month season is assigned to its centre month (DJF -> Jan, ..., NDJ -> Dec);
%     the ANOM column is used.
%   * Year-by-month tables (NCEI ersst.v5.pdo.dat, PSL *.data): rows "YYYY v1 ... v12".
%     Values with |v| >= 9 are missing-value codes and are dropped.
txt = splitlines(fileread(file));
seasons = {'DJF','JFM','FMA','MAM','AMJ','MJJ','JJA','JAS','ASO','SON','OND','NDJ'};
X = zeros(0, 3);
if any(contains(txt(1:min(5, end)), 'SEAS'))
    info.format = 'CPC ONI seasonal table (ANOM column, centre month)';
    for i = 1:numel(txt)
        tok = strsplit(strtrim(txt{i}));
        if numel(tok) >= 4 && any(strcmp(tok{1}, seasons))
            m = find(strcmp(tok{1}, seasons)); y = str2double(tok{2}); v = str2double(tok{4});
            if isfinite(y) && isfinite(v), X(end+1, :) = [v y m]; end %#ok<AGROW>
        end
    end
else
    info.format = 'year-by-month table (missing codes |v|>=9 dropped)';
    for i = 1:numel(txt)
        tok = strsplit(strtrim(txt{i}));
        if numel(tok) == 13
            v = str2double(tok);
            if all(isfinite(v)) && v(1) == round(v(1)) && v(1) >= 1850 && v(1) <= 2100
                for m = 1:12
                    if abs(v(m+1)) < 9, X(end+1, :) = [v(m+1) v(1) m]; end %#ok<AGROW>
                end
            end
        end
    end
end
if isempty(X), error('No index values could be read from %s', file); end
[~, o] = sortrows(X(:, 2:3)); X = X(o, :);
info.first = X(1, 2:3); info.last = X(end, 2:3); info.n = size(X, 1);
info.range = [min(X(:, 1)) max(X(:, 1))];
end
