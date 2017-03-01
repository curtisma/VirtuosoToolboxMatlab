classdef cornerSet < matlab.mixin.SetGet & matlab.mixin.Copyable
    %cornerSet A set of Corners
    %   A corner set containing multiple individual corners
    %
    % PARAMETERS and PROPERTIES
    %  Corners - An adexl.corner object or array of objects.
    %  ProcessCorner - The process corner [Char]
    %  Temp - Temperature [numeric]
    %  Variables - Set of variables [adexl.variables]
    %  Process - The process of the design
    % METHODS
    %  sklCmds = skill(MipiStates) - Generates a set of skill commands for
    %   adding the corner set to an adexl state [cell array]
    %  ocnCmds = ocean(MipiStates) - Generates a set of ocean commands
    %   adding the corner set to an ocean test
    % SEE ALSO: adexl.corner, adexl.cellview
    
    properties
        Name
        Corners adexl.corner
        Temp
        ProcessCorner
        Variables adexl.variables
%         Parameters
%         ModelFiles
%         ModelGroups
        Process
        Test
        Spec
    end
    properties (Dependent)
        SkillHandle
    end
    methods
        function obj = cornerSet(varargin)
        %cornerSet create a new ADEXL cornerSet object
        %
        % See also: adexl.cornerSet
            p = inputParser;
%             p.KeepUnmatched = true;
            p.addOptional('Name','',@ischar);
            p.addParameter('Corners',adexl.corner.empty,@(x) isa(x,'adexl.corner'));
%             p.addParameter('DUT',cdscell.empty,@(x) isa(x,'cdsCell'));
            p.addParameter('ProcessCorner','',@ischar);
            p.addParameter('Temp',[],@isnumeric);
            p.addParameter('Variables',adexl.variables.empty,@(x) isa(x,'adexl.variables'));
            p.addParameter('Process',processes.GENERIC.empty,@(x) isa(x,'cdsProcess'));
            p.addParameter('Spec',adexl.spec.empty,@(x) isa(x,'adexl.spec'));
            p.parse(varargin{:});
            obj.Name = p.Results.Name;
            obj.Corners = p.Results.Corners;
            
            % Setup parameters
            obj.Process = p.Results.Process;
            obj.ProcessCorner = p.Results.ProcessCorner;
            obj.Temp = p.Results.Temp;
            obj.Variables = p.Results.Variables;
            obj.Spec = p.Results.Spec;
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
        function ocn = ocean(obj,MipiStates)
            ocn{1} = [';---------- Corner "' obj.Name '" -------------'];
            ocn{1} = ['ocnxlCorner( "' obj.Name '"'];
            % Variables
%             ocnVariables = cellfun(@(varName) ['      ("variable" "' varName '" "' num2str(obj.Variables.(varName)) '")'],obj.Variables.names,'UniformOutput',false);
            ocnVariables = obj.Variables.ocean('corners',MipiStates);
            ocn = [ocn'; ocnVariables];
            % Process
            if(obj.Variables.isVariable('SET_PROCESS'))
                if(ischar(obj.Variables.SET_PROCESS))
                    processSections = ['\"' obj.Variables.SET_PROCESS '\" '];
                elseif(iscell(obj.Variables.SET_PROCESS))
%                     processSections = ['\"' obj.Variables.SET_PROCESS '\" '];
                    warning('Need to update cornerSet to handle multiple process corners');
                else
                    error('skyVer:cornerSet:SET_PROCESS','SET_PROCESS variable must be a char or cell');
                end
                ocn{end+1} = ['      ("model" "' obj.Process.Paths.unixPath('ModelFile') '" ?section "' processSections '")'];
            else
                ocn{end+1} = ['      ("model" "' obj.Process.Paths.unixPath('ModelFile') '" ?enabled nil ?section "")'];
            end
            % ModelPath is wrong
            
            ocn{end+1} = '   )';
            ocn{end+1} = ')';
        end
        function skl = skill(obj,MipiStates)
            skl{1} = [';CORNER ' obj.Name];
            skl{2} = [obj.SkillHandle ' = axlPutCorner(sdb "' obj.Name '")'];
            % Variables
            
            skl = [skl'; obj.Variables.skill('corners',MipiStates)'];
            skl{end+1} = ['axlPutVarList(' obj.SkillHandle ' varList)'];
            % Spec
            if(~isempty(obj.Spec))
            skl{end+1} = obj.Spec.skill;
            end
            % Process
            if(obj.Variables.isVariable('SET_PROCESS'))
                if(ischar(obj.Variables.SET_PROCESS))
                    processSections = obj.Variables.SET_PROCESS;
                elseif(iscell(obj.Variables.SET_PROCESS))
                    warning('Need to update cornerSet to handle multiple process corners');
                else
                    error('skyVer:cornerSet:SET_PROCESS','SET_PROCESS variable must be a char or cell');
                end
                skl{end+1} = ['modelHandle=axlPutModel(' obj.SkillHandle ' "header_MIPI.scs")'];
                skl{end+1} = ['axlSetModelFile(modelHandle "' obj.Process.Paths.unixPath('ModelFile') '")'];
                skl{end+1} = ['axlSetModelSection(modelHandle "' processSections '")'];
            else
                % Nominal Corner
%                 skl{end+1} = 'modelHandle=axlPutModel(cornerH "header_MIPI.scs")';
%                 skl{end+1} = ['axlSetModelFile(modelHandle "' obj.Process.Paths.unixPath('ModelFile') '")'];
%                 skl{end+1} = 'axlSetModelSection(modelHandle "")';
            end
            % Test Enables and Disables
%             skl{end+1} = ['axlSetCornerTestListEnabled(CH_' obj.Name ' ' cdsSkill.cellStr2list({obj.Test.Name}) ' t)']; % Ensure the selected tests are enabled
%             skl{end+1} = ['axlSetCornerTestListEnabled(CH_' obj.Name ' ' cdsSkill.cellStr2list(setdiff({obj.Test.Adexl.Tests.Name},{obj.Test.Name})) ' nil)']; % Disable unselected tests
%             for testEnNum = 1:length(obj.AdexlView.Tests)
%                 if(~strcmp(obj.Adexl.Tests(testEnNum).Name,obj.Name))
%                     skl{end+1} = ['axlSetCornerTestEnabled(cornerH "' obj.AdexlView.Tests(testEnNum).Name '" nil)'];
%                 else
%                     skl{end+1} = ['axlSetCornerTestEnabled(cornerH "' obj.AdexlView.Tests(testEnNum).Name '" t)'];
%                 end
%             end
%             cdsSkill.cellStr2list({obj.Test.Adexl.Tests.Name})
        end
        function skl = get.SkillHandle(obj)
            skl = ['CH_' obj.Name];
        end
    end
    methods (Static)
%         function obj = loadSTCrow(Name,Temp,ProcessCorner,varargin)
%             for varNum = 1:length(varargin)
%                 strsplit = 
%             end
%         end
    end
end

