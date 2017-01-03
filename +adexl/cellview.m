classdef cellview < matlab.mixin.SetGet & matlab.mixin.Copyable
    %adexl.cellview An ADEXL cellview
    %   represents an ADEXL cellview
    %
    % USAGE
    %  adexl = 
    % INPUTS
    %  Cell - Cell which contains this Adexl view cdsCell
    % PARAMETERS & PROPERTIES
    %  Tests - The ADE L tests
    % See Also: adexl.test, adexl.corner
    
    properties
        Cell cdsCell % Cell which contains this Adexl view
        Tests adexl.test % ADE L Tests
        
%         CornerSets
%         outputs
%         tests
%         corners
%         globalVars
    end
    
    methods
        function obj = cellview(cell,varargin)
        %cellview Create a new adexl.cellview object
        %
        % See also: adexl.corner
            p = inputParser;
            p.KeepUnmatched = true;
            p.addRequired('cell',@(x) isa(x,'cdsCell'));

            % Setup Parameters
%             p.addParameter('ProcessCorner','',@ischar);
%             p.addParameter('Temp',[],@isnumeric);
%             p.addParameter('Variables',adexl.variables.empty,@(x) isa(x,'adexl.variables'));
            p.addParameter('Tests',adexl.test.empty,@(x) isa(x,'adexl.test'));
%             p.addParameter('test',@islogical);
            p.parse(cell,varargin{:});
%             obj.Process = p.Results.Process;
            
            obj.Cell = p.Results.cell;
            obj.Tests = p.Results.Tests;
        end
%         function addTest(test)
%             
%         end
%         function writeADEXLstate(file)
%             
%         end
%         function writeOutputs(file)
%             
%         end
    end
    
end

