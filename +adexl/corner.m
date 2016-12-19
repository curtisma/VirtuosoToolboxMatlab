classdef corner < matlab.mixin.SetGet
    %axlCorners A set of Cadence ADE XL Corner(s)
    %   The corners can define the PVT and functional parameters of a
    %   simulation by defining variables, parameters, model data, etc.  
    
    properties
        Name
%         cornersTable % Each row is a corner, each column is an item
        Variables
%         Parameters
        ModelFiles
%         ModelGroups
        Tests
    end
    
    methods
        function obj = axlCorners(Name,varargin)
            % Parse Inputs
            p = inputParser;
%             p.KeepUnmatched = true;
            p.addRequired('Name',@ischar);
            p.addParameter('Variables',axlVariables,@(x) isa(x,'axlVariables'));
%             p.addParameter('DUT',cdscell.empty,@(x) isa(x,'cdsCell'));
            p.parse(varargin{:});
        end
        function writeCorners
    end
    
end

