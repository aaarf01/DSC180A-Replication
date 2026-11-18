function [M, D] = ddd2mmdd(yr, yd)
% Stand-in for the File Exchange function ddd2mmdd, which the authors'
% prepare_time_files.m calls but which is not bundled with their code.
% Converts year + day-of-year to month and day of month. (Written for this
% reproduction; logged as a substituted dependency.)
v = datevec(datenum(yr(:), 1, 1) + yd(:) - 1);
M = v(:, 2);
D = v(:, 3);
end
