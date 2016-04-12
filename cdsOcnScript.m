classdef cdsOcnScript
    %cdsOcnScript Class for a Cadence Ocean Script
    %   A Class describing an Ocean script for Cadence Virtuoso IC design suite
    
    properties
        cellName
        ocnBinDir
    end
    
    methods
        function out = run(obj)
            [status, out] = unix(['/rds/prod/HOTCODE/bin/rfbin/ocean -nograph -replay ' script]);
            if(status ~= 0)
                error('runOcean:badExitStatus', 'Ocean script failed %s', out);
            end
        end
    end
    
end

