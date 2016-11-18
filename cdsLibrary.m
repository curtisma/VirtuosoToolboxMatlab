classdef cdsLibrary < matlab.mixin.SetGet
    %cdsLibrary A Cadence Library
    %   Basic information about the library
    %
    % USAGE
    %  library = cdsLibrary(Name)
    %
    % INPUTS & PROPERTIES
    %  Name - name of the library [char]
    %
    % See Also: cdsCell
    
    properties
        Name
        Cells
    end
    
    methods
    	function obj = cdsLibrary(Name,varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.addRequired('Name',@ischar);
            p.parse(Name,varargin{:});
            
            obj.Name = Name;
        end
        function set.Name(obj,val)
            if(~ischar(val))
                error('VirtuosoToolbox:cdsCell:notChar','Name must be a char')
            end
            obj.Name = val;
        end
        
    end
    
end

