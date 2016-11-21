classdef cdsCellAbstract < matlab.mixin.SetGet
    %cdsCellAbstract An Abstract class of a Cadence cell
    %   An abstract cell that allows the cdsLibrary class to be subclassed
    %   and still work with cdsCell
    % See Also:
    
    properties
        Pinout skyPinout
    end
    properties (Abstract)
        Library
    end
    properties (SetAccess = protected)
        Name
    end
    methods
        function obj = cdsCellAbstract(Name,varargin)
        %bandgap Construct a new cdsCell cell object
        %   See class description for usage information
        %
        % See also: cdsCell
            p = inputParser;
            p.KeepUnmatched = true;
            p.addRequired('Name',@ischar);
            p.addParameter('Pinout',skyPinout.empty,@(x) isa(x,'skyPinout') || ischar(x));
            p.parse(Name,varargin{:});
            
            obj.Name    = p.Results.Name;
            if(ischar(p.Results.Pinout))
                obj.Pinout  = skyPinout(p.Results.Pinout);
            else
                obj.Pinout  = p.Results.Pinout;
            end
        end
        function set.Name(obj,val)
            if(~ischar(val))
                error('VirtuosoToolbox:cdsCell:notChar','name must be a char')
            end
            obj.Name = val;
        end
    end
    
end

