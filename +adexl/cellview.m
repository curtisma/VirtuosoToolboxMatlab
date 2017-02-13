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
    properties (Hidden)
        StateDirInt
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
            ocn{9} = ['ocnxlTargetCellView( "' obj.Cell.Library.UserLibraryName '" "' obj.Cell.Name '" "adexl")'];
            ocn{10} = 'ocnxlResultsLocation( "" )';
            ocn{11} = 'ocnxlSimResultsLocation( "" )';
            ocn{12} = '';
            ocn{13} = ';====================== Tests setup ============================================';
            ocn{14} = '';
            ocn = ocn';
            % Tests
            ocnTests = arrayfun(@(x) x.ocean(obj.MipiStates), obj.Tests,'UniformOutput',false);
            ocnTests = reshape([ocnTests{:}],[],1);
            ocn = [ocn; ocnTests];
            ocn{end+1} = '';
            % Global Variables
            ocn{end+1} = ';====================== Sweeps setup ===========================================';
            ocn = [ocn; obj.Variables.ocean('global')];
            ocn{end+1} = '';
            ocn{end+1} = ';====================== Checks and Asserts setup ============================================';
            ocn{end+1} = 'ocnxlPutChecksAsserts(?netlist nil)';
            ocn{end+1} = '';
            ocn{end+1} = ';====================== Test v/s corners setup =================================';
            ocn{end+1} = '';
            ocn{end+1} = ';====================== Job setup ==============================================';
            ocn{end+1} = 'ocnxlJobSetup( ''(';
            ocn{end+1} = '    "blockemail" "1"';
            ocn{end+1} = '    "configuretimeout" "-1"';
            ocn{end+1} = '    "distributionmethod" "LBS"';
            ocn{end+1} = '    "lingertimeout" "60"';
            ocn{end+1} = '    "maxjobs" "12"';
            ocn{end+1} = '    "name" "SWKS Default"';
            ocn{end+1} = '    "preemptivestart" "0"';
            ocn{end+1} = '    "reconfigureimmediately" "1"';
            ocn{end+1} = '    "runtimeout" "-1"';
            ocn{end+1} = '    "showerrorwhenretrying" "1"';
            ocn{end+1} = '    "showoutputlogerror" "0"';
            ocn{end+1} = '    "startmaxjobsimmed" "1"';
            ocn{end+1} = '    "starttimeout" "-1"';
            ocn{end+1} = '    "usesameprocess" "0"';
            ocn{end+1} = ') )';
            ocn{end+1} = '';
            % Corners
            ocnCorners = arrayfun(@(x) x.CornerSet.ocean(obj.MipiStates), obj.Tests,'UniformOutput',false);
            ocnCorners = reshape([ocnCorners{:}],[],1);
            ocn = [ocn; ocnCorners];
            % Disabled Items
            ocn{end+1} = ';====================== Disabled items =========================================';
            ocn = [ocn; obj.Variables.ocean('globalDisableAll')];
            ocn{end+1} = '';
            ocn{end+1} = ';====================== Run Mode Options ======================================';
            ocn{end+1} = ['ocnxlSaveSetupAs( "' obj.Cell.Library.UserLibraryName '" "' obj.Cell.Name '" "adexl")'];
            ocn{end+1} = '';
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
        function varargout = skill(obj,varargin)
            skl{1} = '/* ADEXL Cellview Generation Ocean Script';
            skl{2} = ['Library: ' obj.Cell.Library.Name];
            skl{3} = ['Cell: ' obj.Cell.Name];
            skl{4} = '*/';
            skl{5} = ';====================== Load Skill Functions ============================================';
            skl{6} = ['load("' skySkill.axlFunctionPath '")'];
            skl{7} = ';====================== Open Setup ============================================';
            skl{8} = ['ddGetObj("' obj.Cell.Library.UserLibraryName '" "' obj.Cell.Name '" "adexl" "data.sdb" nil "w")']; % Create cellview
            skl{9} = 'sessionName = strcat("mysession" (sprintf nil "%d" random()))';
            skl{10} = 'axlSession = axlCreateSession(sessionName)';
%             sdb = axlNewSetupDBLCV("myLib" "myCell" "myView")
            skl{11} = ['sdb = axlSetMainSetupDBLCV( axlSession "' obj.Cell.Library.UserLibraryName '" "' obj.Cell.Name '" "adexl")'];
            skl{12} = '';
            
            % Setup Tests
            % Tests
            sklTests = arrayfun(@(x) x.skill(obj.MipiStates), obj.Tests,'UniformOutput',false);
            sklTests = reshape(cat(1,sklTests{:}),[],1);
            skl = [skl'; sklTests];
            skl{end+1} = '';
            
            skl{end+1} = ';====================== Disables ============================================';
            skl{end+1} = 'axlSetAllVarsDisabled(sdb 1)'; % Disable All Global Variables
            skl{end+1} = 'axlSetNominalCornerEnabled(sdb 0)'; % Disable All Nominal Corners
%             for outerTest = 1:length(obj.Tests)
%                 for innerTest = 1:length(obj.Tests)
%                     
%                 end
%             end
            skl{end+1} = '';
            
            skl{end+1} = ';====================== Save Setup ============================================';
            skl{end+1} = 'axlSaveSetup(axlSession)';
            skl{end+1} = 'axlCommitSetupDB( sdb )';
            skl{end+1} = 'axlCloseSetupDB( sdb )';
%             if(nargin == 1)
%                 fid = fopen(fullfile(obj.Cell.DUT.Path,[obj.Cell.Name '.il']),'w');
%                 cellfun(@(sklChar) fprintf(fid,'%s\n',sklChar), skl);
%                 fclose(fid);
%             elseif(nargin == 2)
%                 fid = fopen(varargin{1},'w');
%                 cellfun(@(sklChar) fprintf(fid,'%s\n',sklChar), skl);
%                 fclose(fid);
%             end
            if(nargin == 1)
                runOutput = cdsRunSkill(fullfile(obj.Cell.DUT.Path,[obj.Cell.Name '.il']),obj.Cell.Library,skl,true);
            elseif(nargin == 2)
                runOutput = cdsRunSkill(varargin{1},obj.Cell.Library,skl,true);
            end
            if(nargout == 1)
                varargout = skl;
            elseif(nargout == 2)
                varargout = {skl runOutput};
            end
        end
    end
    
end

