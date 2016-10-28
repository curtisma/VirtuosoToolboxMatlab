classdef cdsLibrary < matlab.mixin.SetGet
    %cdsLibrary A Cadence Library
    %   Basic information about the library
    %
    % USAGE
    %  library = cdsLibrary(name)
    properties
        name 
    end
    
    methods
    	function obj = cdsCell(name,varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.addRequired('name',@ischar);
            p.parse(varargin{:});
            
            obj.name = name;
        end
        function set.name(obj,val)
            if(~ischar(val))
                error('VirtuosoToolbox:cdsCell:notChar','name must be a char')
            end
            obj.name = val;
        end
        
    end
    
end

