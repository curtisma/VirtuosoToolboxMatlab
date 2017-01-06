classdef cdsCell < cdsCellAbstract
    %cdsCell A Cadence cell
    %   Basic cell information
    %
    % USAGE
    %  cell = cdsCell(name,...)
    % INPUTS and PROPERTIES
    %  Name - cellname [char]
    % PARAMETERS and PROPERTIES
    %  Library - library name or cdsLibrary object [cdsLibrary or char]
    %  Pinout - skyPinout object representing the pinout of the cell.
    %   [skyPinout]
    % see also: cdsLibrary
    
    properties
        Library
    end
    methods
        function obj = cdsCell(Name,varargin)
        %bandgap Construct a new cdsCell cell object
        %   See class description for usage information
        %
        % See also: cdsCell
            obj@cdsCellAbstract(Name,varargin{:});
            p = inputParser;
            p.KeepUnmatched = true;
            p.addParameter('Library',cdsLibrary.empty,@(x) ischar(x) || isa(x,'cdsLibrary'));
            p.parse(varargin{:});
            obj.Library = p.Results.Library;
        end
        function set.Library(obj,val)
            if(ischar(val))
                val = cdsLibrary(val);
            end
            obj.Library = val;
        end
        function create(obj)
        %create Creates a new cellview in the Cadence database
        % 
            if(isempty(obj.library) || isempty(obj.Name))
                error('VirtuosoToolbox:cdsCell:FullDefinition','Need to define the library and cell names');
            end
        end
    end
end

