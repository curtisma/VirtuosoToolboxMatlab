classdef test < adexl.resultsInterface
    %test Cadence ADE XL test
    %   Defines and collects the data for a single Cadence test
    %   
    % USAGE
    %  obj = adexl.test(corner ...)
    % INPUTS
    %  Corner - First corner for this test [cdsOutCorner](optional)

    % PARAMETERS
    %  Result - Cadence run for this test [cdsOutRun](optional)
    %  Desktop - Opens a new desktop if one isn't open yet (logical)
    % Parameters  & Properties
    %  Design - The design to be simulated [skyCell or cdsCell]
    %  Outputs - The simulation result outputs [adexl.output]
    %  SaveAllVoltages - If true, all voltages in the design are saved.  
    %                    If fasle, only select voltages are saved
    %   Selected currents are saved by default.
    %  CornerSet
    % PROPERTIES
    %  Analyses - 
    %  
    % See also: adexl.corner, adexl.test, adexl.result, adexl.cellview
    
    
    
    %  signals - defines the signals to save
    %  transientSignals - defines the signals to save only for a
    %   transient analysis
    %  dcSignals - defines the signals to save only for a
    %   dc analysis`
    properties
        Design
        Analyses
        CornerSet adexl.cornerSet
        Corners % An array of cdsOutCorners arranged by simNum
        Variables adexl.variables
        Outputs adexl.output
        Temp % Nominal Temperature
        Names
        Paths
        Process
        Result
        SaveAllVoltages
        AdexlView
        Enable
    end
    properties (Constant)
        Simulator = 'spectre';
    end
    properties (Transient)
        CornerDoneCnt
    end
    properties (Dependent)
        Done
        AnalysisNames
    end
    methods
        function obj = test(varargin)
        %test create a new ADEXL test object
        %
        % See also: adexl.test
        
%             obj@cdsOut(
%             if(isa(varargin{1},'cdsOutCorner'))
%                 if(isa(varargin{1},'cdsOutRun'))
%                     if(nargin>2)
%                         obj = obj@cdsOut(varargin{3:end}); % Superclass constructor
%                     else
%                         obj = obj@cdsOut; % Superclass constructor
%                     end
%                 elseif(nargin>1)
%                     obj = obj@cdsOut(varargin{2:end}); % Superclass constructor
%                 else
%                     
%                 end
%             else
%                 obj = obj@cdsOut(varargin{:}); % Superclass constructor
%             end
            obj = obj@adexl.resultsInterface(varargin{:}); % Superclass constructor
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('corner',adexl.corner.empty,@(x) isa(x,'adexl.corner'));
%             p.addOptional('Result',cdsOutRun.empty,@(x) isa(x,'cdsOutRun'));
            p.addParameter('Analyses',analyses.DC.empty,@(x) isa(x,'analyses.analysisInterface'));
            p.addParameter('Corners',adexl.corner.empty,@(x) isa(x,'adexl.corner'));
            p.addParameter('CornerSet',adexl.cornerSet.empty,@(x) isa(x,'adexl.cornerSet'));
            p.addParameter('Design',cdsCell.empty,@(x) isa(x,'cdsCellAbstract'));
            p.addParameter('Variables',adexl.variables.empty,@(x) isa(x,'adexl.variables'));
            p.addParameter('Temp',[],@isnumeric);
            p.addParameter('Outputs',adexl.output.empty,@(x) isa(x,'adexl.output'));
            p.addParameter('AdexlView',adexl.cellview.empty,@(x) isa(x,'adexl.cellview'));
            p.addParameter('SaveAllVoltages',false,@islogical);
            p.parse(varargin{:});
            obj.CornerDoneCnt = 0;
            
            % Add first corner
            obj.Corners = p.Results.Corners;
            obj.CornerSet = p.Results.CornerSet;
            obj.Analyses = p.Results.Analyses;
            obj.Design = p.Results.Design;
            obj.Variables = p.Results.Variables;
            obj.Temp = p.Results.Temp;
            obj.SaveAllVoltages = p.Results.SaveAllVoltages;
            if(~isempty(p.Results.corner))
                if(nargin >1)
                    obj.addCorner(p.Results.corner,varargin{2:end});
                else
                    obj.addCorner(p.Results.corner);
                end
            end
        end
        function set.Corners(obj,val)
%             if(~isempty(val))
% %                 if(~strcmp(obj.name, val.Names.test))
% %                 % Check that this corner is for this test
% %                     error('VirtuosoToolbox:cdsOutTest:setCorners','Wrong test name');
% %                 end
%                 val.test = obj;
%             end
            if(~isa(val,'adexl.corner'))
                error('VirtuosoToolbox:adexlTest:addCorner','corner must be a adexl.corner');
            end
            obj.Corners = val;
%             if(exist('obj.Info.corner','var') && isempty(obj.Info.corner))
%                 obj.getCornerList;
%             end
        end
        function addCorner(obj,corner,varargin)
            corner = addCorner@cdsOut(obj,corner,varargin{:});
            if(isempty(obj.Corners) && ~isempty(corner))
            % initialize test with the properties of the given corner
                obj.Name = corner.Names.test;
                obj.Names.result = corner.Names.result;
                obj.Names.library = corner.Names.library;
            elseif(~isempty(obj.Corners) && ~isempty(corner))
                if(~strcmp(obj.Name, corner.Names.test))
                % Check that this corner is for this test
                    error('VirtuosoToolbox:cdsOutTest:setCorners','Wrong test name');
                end
            end
            corner.test = obj;
            obj.Corners(corner.simNum) = corner;
            if(any(strcmp('stb-stb',corner.Info.availableAnalyses)))
                if(~any(strcmp('stb-margin.stb',corner.Info.availableAnalyses)))
                end
                obj.Analyses.stb.loadData(corner);
            end
            obj.Names = corner.Names;
            obj.Paths = corner.Paths;
            obj.CornerDoneCnt = obj.CornerDoneCnt +1;
            obj.Process = corner.Process;
            if(isempty(obj.Info) || (isempty(obj.Info) && ~isfield(obj.Info,'cornerNames')))
                obj.getCornerList;
            end
            if(isfield(obj.Info,'cornerNames') && ~isempty(obj.Info.cornerNames))
                corner.Name = obj.Info.cornerNames{corner.simNum};
            end
        end
        function getAllPropertiesCorners(obj)
        % Corners psf properties
            obj.Info.Corners.tranDatasets = cds_srr(obj.Paths.psfPathCorners,'tran-tran');
            cornerProperties = obj.Info.Corners.tranDatasets.prop;
            for i = 1:length(cornerProperties)
                obj.Info.Corners.properties.(regexprep(cornerProperties{i},'\(|\)|\.| ','')) = ...
                cds_srr(obj.Paths.psfPathCorners,'tran-tran',cornerProperties{i});
            end
        end
        function getCornerList(obj)
        % Corner Info
            if(~isempty(obj.Corners))
                obj.Paths.psfPathCorners = strjoin([obj.Paths.psfLocFolders(1:11) 'psf' obj.Paths.psfLocFolders(13) 'psf'],filesep);
                obj.Paths.Result = strjoin(obj.Paths.psfLocFolders(1:11),filesep);
                obj.Paths.psfTmp = strjoin([obj.Paths.psfLocFolders(1:10) ['.tmpADEDir_' obj.Names.user] obj.Names.test [obj.Names.library '_' obj.Names.testBenchCell '_' obj.Names.cellView '_spectre'] 'psf'],filesep);
                psfPathCornersContents = dir(obj.Paths.psfPathCorners);
                if(length({psfPathCornersContents.name}) > 2)
                    obj.Paths.runObjFile = strjoin({obj.Paths.psfPathCorners 'runObjFile'},filesep);
                else
                    obj.Paths.runObjFile = strjoin({obj.Paths.psfTmp 'runObjFile'},filesep);
                end
                obj.Info.runObjFile = cdsOutMatlab.loadTextFile(obj.Paths.runObjFile);
                if(isempty(obj.Info.runObjFile))
                    obj.dir(obj.Paths.runObjFile);
                    disp(obj.Info.dir.(obj.Paths.runObjFile).Names);
                    disp(obj.Paths.runObjFile);
                end
                numCornerLineNum = strncmp('"Corner_num"',obj.Info.runObjFile,12);
                if(~any(numCornerLineNum))
%                     cornerRowsIdx = strncmp('"Corner=',obj.Info.runObjFile,8);
                    simNum = regexp(obj.Info.runObjFile,'"dataDir" "(?:\.\./)+(.*/)','tokens');
                    simNum = simNum(cellfun(@(x) ~isempty(x),simNum));
                    simNum = cellfun(@(x) str2double(x{1}{1}(1:end-1)),simNum);
%                     [~,simNumOrderedIdx] = sort(simNum);
                    cornerNames = regexp(obj.Info.runObjFile,'"Corner" "(.*)"','tokens');
                    cornerNames = cornerNames(cellfun(@(x) ~isempty(x),cornerNames));
                    cornerNames = cellfun(@(x) char(x{1}),cornerNames,'UniformOutput',false);
                    cornerNamesOrdered = cell(max(simNum),1);
                    cornerNamesOrdered(simNum) = cornerNames;
                    obj.Info.cornerNames = cornerNamesOrdered;
                    obj.Info.numCorners = length(cornerNamesOrdered);
%                     cornerNamse = cellfun(@(x,y) 
                else
                    obj.Info.numCorners = str2double(obj.Info.runObjFile{numCornerLineNum}(13:end));
                    cornerNames = {obj.Info.runObjFile{find(numCornerLineNum)+1:find(numCornerLineNum)+obj.Info.numCorners}};
                    obj.Info.cornerNames = cellfun(@(x,y) x(y(3)+1:end-1),cornerNames,strfind(cornerNames,'"'),'UniformOutput',false);
                end
%                 obj.Names.corner = obj.Info.cornerNames{obj.simNum};
%                 obj.getCornerInfo;
            end
        end
        function getPaths(obj)
            obj.Paths.project = char(strjoin({'','prj',obj.Names.project},filesep));
            obj.Paths.doc = fullfile(obj.Paths.project,'doc');
            obj.Paths.matlab = fullfile(obj.Paths.doc,'matlab');
            obj.Paths.result = char(strjoin(obj.Paths.psfLocFolders(1:11),filesep));
%             obj.Paths.testData = 
        end
        function val = get.Done(obj)
            if(isstruct(obj.Info) && isfield(obj.Info,'numCorners') && ~isempty(obj.Corners))
                cornersAvailable = sum(cellfun(@(x) ~isempty(x),{obj.Corners.simNum}));
                val = (cornersAvailable == obj.Info.numCorners);
            else
                val = false;
                warning('skyVer:cdsOutTest:get_Done','numCorners Unavailable');
            end
        end
        function val = get.AnalysisNames(obj)
            val = fieldnames(obj.Corners(1).Analyses);
        end
        function analysis = getAnalysis(obj,analysisName)
            Analyses = [obj.Corners.Analyses];
        	analysis= [Analyses.(analysisName)];
        end
        function dataTable = getDataTable(obj,varargin)
            dataTable = table([obj.Corners.temp]',{obj.Corners.processCorner}');
            dataTable.Properties.VariableNames = {'temp', 'Process'};
            dataTable.Properties.DimensionNames = {'Corner','Variables'};
            vars = [obj.Corners.variables];
            if(~isempty(obj.Process))
                variableNames = setdiff(fieldnames(vars),[obj.Process.variableNames {'temp'}]);
            else
                variableNames = fieldnames(vars);
            end
            varVal = struct;
            for varIdx = 1:length(variableNames)
                varVal.(variableNames{varIdx}) = [vars.(variableNames{varIdx})]';
            end
            dataTable = [dataTable struct2table(varVal)];
            dataTable.Properties.RowNames = {obj.Corners.Name};
        end
        function set.Process(obj,val)
            if(ischar(val))
                val = processes.(val);
            end
            if(~isa(val,'cdsProcess'))
                error('VirtuosoToolbox:cdsOutRun:setProcess','Process must be subclassed from cdsProcess')
            end
            obj.Process = val;
        end
        function ocnOut = ocean(obj,MipiStates)
        %ocean Creates a set of ocean commands to create the test
        %   Returns a cell array of ocean commands for creating the test in
        %   a Cadence Adexl view
        %   Currently assumes the cellview to be simulated is a config view
        %
            ocnOut{1} = [';---------- Test "' obj.Name '" -------------'];
            ocnOut{2} = ['ocnxlBeginTest("' obj.Name '")'];
            ocnOut{3} = sprintf('simulator( ''%s )',obj.Simulator);
            ocnOut{4} = ['design("' obj.Design.Library.UserLibraryName '" "' obj.Design.Name '" "config")'];
            ocnOut = [ocnOut'; obj.Design.Library.Process.OceanModelPath]; % Model Path
            ocnOut = [ocnOut; obj.Design.Library.Process.OceanNomModelFile]; % Nominal Model File Information
            ocnOut = [ocnOut; obj.Analyses.ocean]; % Analysis commands
            ocnOut = [ocnOut; obj.Variables.ocean('test',MipiStates)]; % Design Variables
            ocnOut{end+1} = sprintf('envOption(\n\t''emirSumList nil\n\t''analysisOrder list("dc" "pz" "dcmatch" "stb" "tran" "envlp" "ac" "lf" "noise" "xf" "sp" "pss" "pac" "pstb" "pnoise" "pxf" "psp" "qpss" "qpac" "qpnoise" "qpxf" "qpsp" "hb" "hbac" "hbnoise" "sens" "acmatch")\n)');
            ocnOut{end+1} = sprintf('option( ?categ ''turboOpts\n\t''preserveOption  "None"\n)');
            ocnOut{end+1} = sprintf('temp( %f )',obj.Temp);
            ocnOut = [ocnOut; obj.Outputs.ocean];
            ocnOut{end+1} = sprintf(['ocnxlEndTest() ; "' obj.Name '"']);
            ocnOut{end+1} = '';
        end
        function skl = skill(obj,MipiStates)
            % Setup ADE test state
            skl{1} = [';---------- Test "' obj.Name '" -------------'];
            skl{2} = ['htest = axlPutTest( sdb "' obj.Name '" "ADE")'];
            skl{3} = ['axlSetTestToolArgs( htest list( list("lib" "' obj.Design.Library.UserLibraryName '") '...
                                                      'list("cell" "' obj.Design.Name '") '...
                                                      'list("view" "config") '...
                                                      'list("sim" "' obj.Simulator '"))) '];
            skl{4} = ['testSession = axlGetToolSession(axlSession "' obj.Name '")'];
            skl{5} = 'testSession = asiGetSession(testSession)';
            %skl = [skl'; obj.Design.Library.Process.skillNomModelFile']; % Model Path and file information
            skl = [skl'; obj.Analyses.skill'];                             % Analysis Setup
            skl = [skl; obj.Variables.skill('test',MipiStates)];          % Design Variables
            skl = [skl; obj.Outputs.skill(obj.Name)];
            skl = [skl; obj.CornerSet.skill(MipiStates)];
            % Save All... Options
            if(~obj.SaveAllVoltages)
                skl{end+1} = sprintf('asiSetKeepOptionVal(testSession ''save "selected")');
            end
            skl{end+1} = sprintf('asiSetKeepOptionVal(testSession ''currents "selected")');

            
            % Disable tests that do not belong to this corner
%             skl{end+1:end+length(obj.AdexlView.Tests)-1} = ''; % Preallocate
            for testEnNum = 1:length(obj.AdexlView.Tests)
                if(~strcmp(obj.AdexlView.Tests(testEnNum).Name,obj.Name))
                    skl{end+1} = ['axlSetCornerTestEnabled(cornerH "' obj.AdexlView.Tests(testEnNum).Name '" nil)'];
                end
            end
            % Enable or disable corner
            skl{end+1} = ['axlSetEnabled(htest ' cdsSkill.sklLogical(obj.Enable) ')'];
%             skl{2} = ['axlPutNote( sdb "test"
        end
    end
    
end

