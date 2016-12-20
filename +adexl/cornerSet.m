classdef cornerSet
    %cornerSet A set of Corners
    %   Detailed explanation goes here
    
    properties
        Name
        Corners adexl.corner
        Temp
        Variables adexl.variables
%         Parameters
%         ModelFiles
%         ModelGroups
        Tests
    end
    
    methods
        function obj = cornerSet(varargin)
        end
        function export(obj,file)
        % export Exports the corners to an XML document.  This
        % document can then be used to copy the root node to another
        % document using the importNode or adoptNode methods.
        end
    end
    
end

