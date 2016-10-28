classdef cdsCell < matlab.mixin.SetGet
    %cdsCell A Cadence cell
    %   Basic cell information
    %
    % USAGE
    %  cell = cdsCell(name,...)
    % PARAMETERS
    %  library - library name
    % 
    % see also: cdsLibrary
    
    properties
        name
        library
%         pinout
    end
    
    methods
        function obj = cdsCell(name,varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.addRequired('name',@ischar);
            p.addParameter('library','',@(x) ischar(x) || isa(x,'cdsLibrary'));
%             p.addParameter('pinout',@isa(
            p.parse(name,varargin{:});
            
            obj.name = name;
            
        end
        function set.name(obj,val)
            if(~ischar(val))
                error('VirtuosoToolbox:cdsCell:notChar','name must be a char')
            end
            obj.name = val;
        end
        function set.library(obj,val)
            if(ischar(val))
                val = cdsLibrary(val);
            end
            obj.library = val;
        end
    end
    
end

