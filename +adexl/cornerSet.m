classdef cornerSet
    %cornerSet A set of Corners
    %   A corner set containing multiple individual corners
    
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
        
            if(isa(varargin{1},'skySTC'))
                
            end
        end
        function export(obj,file)
        % export Exports the corners to an XML document.  This
        % document can then be used to copy the root node to another
        % document using the importNode or adoptNode methods.
        end
        function import(obj,STC)
        %import Imports Corners from a STC object
        % 
        % USAGE
        %  obj.import(STC)
        %   Imports the corner sets from the skySTC object, STC.
        %
        % See also: adexl.cornerSet
            
        
        end
    end
    methods (Static)
        function obj = loadSTCrow(Name,Temp,ProcessCorner,varargin)
            for varNum = 1:length(varargin)
                strsplit = 
            end
        end
    end
end

