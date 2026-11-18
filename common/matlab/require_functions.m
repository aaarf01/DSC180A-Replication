function require_functions(names)
% Stop with a clear message if any function is missing from the path.
miss = names(cellfun(@(f) exist(f) == 0, names)); %#ok<EXIST>
if ~isempty(miss)
    error(['Missing functions: %s. Toolbox functions need the Statistics and Machine Learning or ' ...
           'Curve Fitting Toolbox; inpaint_nans needs setup_data (see README).'], strjoin(miss, ', '));
end
end
