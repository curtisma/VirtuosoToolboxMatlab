classdef cellview < matlab.mixin.SetGet & matlab.mixin.Copyable
    %adexl.cellview An ADEXL cellview
    %   represents an ADEXL cellview
    %
    % USAGE
    %  adexl = adexl.cellview
    % INPUTS
    %  Cell - Cell which contains this Adexl view cdsCell
    % PARAMETERS & PROPERTIES
    %  Tests - The ADE L tests
    % See Also: adexl.test, adexl.corner
    
    properties
        Cell % Cell which contains this Adexl view
        Tests adexl.test % ADE L Tests
        Variables adexl.variables % Global "Sweep" Variables
        MipiStates skyMipiStates
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
            p.addRequired('cell',@(x) isa(x,'cdsCellAbstract'));

            % Setup Parameters
%             p.addParameter('ProcessCorner','',@ischar);
%             p.addParameter('Temp',[],@isnumeric);
%             p.addParameter('Variables',adexl.variables.empty,@(x) isa(x,'adexl.variables'));
            p.addParameter('Tests',adexl.test.empty,@(x) isa(x,'adexl.test'));
            p.addParameter('Variables',adexl.variables.empty,@(x) isa(x,'adexl.variables'));
            p.addParameter('MipiStates',skyMipiStates.empty,@(x) isa(x,'skyMipiStates'));
%             p.addParameter('test',@islogical);
            p.parse(cell,varargin{:});
%             obj.Process = p.Results.Process;
            
            obj.Cell = p.Results.cell;
            obj.Tests = p.Results.Tests;
            obj.MipiStates = p.Results.MipiStates;
            obj.Variables = p.Results.Variables;
            if(~isempty(obj.Tests) && isempty(obj.Variables))
                obj.Variables = obj.Tests(1).Variables;
            end
            obj.Variables = p.Results.Variables;
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
        function ocn = ocean(obj,varargin)
        
            ocn{1} = '/* ADEXL Cellview Generation Ocean Script';
            ocn{2} = ['Library: ' obj.Cell.Library.Name];
            ocn{3} = ['Cell: ' obj.Cell.Name];
            ocn{4} = '*/';
            ocn{5} = '';
            ocn{6} = ';====================== Set to XL Mode =========================================';
            ocn{7} = 'ocnSetXLMode()';
            ocn{8} = ['ocnxlProjectDir( "/prj/' obj.Cell.Library.Name '/work_libs/' obj.Cell.Library.Username '/cds/simulation")'];
            ocn{9} = ['ocnxlTargetCellview( "' obj.Cell.Library.UserLibraryName '" "adexl")'];
            ocn{10} = 'ocnxlResultsLocation( "" )';
            ocn{11} = 'ocnxlSimResultsLocation( "" )';
            ocn{12} = '';
            ocn{13} = ';====================== Tests setup ============================================';
            ocn{14} = '';
            ocn = ocn';
            % Tests
            ocnTests = arrayfun(@(x) x.ocean, obj.Tests,'UniformOutput',false);
            ocnTests = reshape([ocnTests{:}],[],1);
            ocn = [ocn; ocnTests];
            % Global Variables

            % Corners
            ocnCorners = arrayfun(@(x) x.CornerSet.ocean(obj.MipiStates), obj.Tests,'UniformOutput',false);
            ocnCorners = reshape([ocnCorners{:}],[],1);
            ocn = [ocn; ocnCorners];
            % Disabled Items
            ocn{end+1} = ';====================== Run Mode Options ======================================';
            ocn{end+1} = ['ocnxlSaveSetupAs( "' obj.Cell.Library.UserLibraryName '" "adexl")'];
            ocn{end+1} = ['ocnxlSaveSetupAs( "' obj.Cell.Library.UserLibraryName '" "adexl")'];
            ocn{end+1} = ';====================== Starting Point Info ======================================';
            ocn{end+1} = '';
            ocn{end+1} = ';====================== Run command ============================================';
            ocn{end+1} = '';
            ocn{end+1} = ';====================== End XL Mode command ===================================';
            ocn{end+1} = 'ocnxlEndXLMode()';
            if(nargin == 2)
                fid = fopen(varargin{1},'w');
                cellfun(@(ocnChar) fprintf(fid,'%s\n',ocnChar), ocn);
            end
        end
    end
    
end

