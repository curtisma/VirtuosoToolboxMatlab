function out = runOcean(script)
%runOcean Runs an ocean script 
%   Runs a Cadence Virtuoso Ocean script locally
[status, out] = unix(['/rds/prod/HOTCODE/bin/rfbin/ocean -nograph -replay ' script]);
if(status ~= 0)
    error('runOcean:badExitStatus', 'Ocean Exit status not 0');
end

end

