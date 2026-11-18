function start_log(logfile)
if exist(logfile, 'file'), delete(logfile); end
diary(logfile); diary on
end
