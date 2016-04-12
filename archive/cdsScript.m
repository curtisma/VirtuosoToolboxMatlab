classdef cdsScript
    %cdsScript Cadence Script Class
    %   Detailed explanation goes here
    
    properties
		fileName
		description
		type
    end
    
    methods
        
        function obj = cdsScript(varargin)
        % obj = cdsScript(fileName)
        % obj = cdsScript(fileName,description)
        % obj = cdsScript(fileName,description,type)
            obj.fileName = filename;
            if(nargin>1)
                obj.description = varargin{2};
            end
            if(nargin>2)
                obj.type = varargin{3};
            end
        end
		function write(obj)
        end
		function open(obj)
            open(obj.fileName);
        end
    end
    
end

