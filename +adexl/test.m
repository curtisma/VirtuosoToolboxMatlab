classdef test < cdsOut
    %axlTest Cadence ADE XL test
    %   Defines and collects the data for a single Cadence test
    %   
    % USAGE
    %  obj = adexl.test(Result, corner ...)
    % INPUTS
    %  Corner - First corner for this test [cdsOutCorner](optional)
    %  Result - Cadence run for this test [cdsOutRun](optional)
    %  signals - defines the signals to save
    %  transientSignals - defines the signals to save only for a
    %   transient analysis
    %  dcSignals - defines the signals to save only for a
    %   dc analysis
    %  desktop - Opens a new desktop if one isn't open yet (logical)
    properties
        Analyses
        Corners % An array of cdsOutCorners arranged by simNum
        Result
        Names
        Paths
        Process
    end
    properties (Transient)
        CornerDoneCnt
    end
    properties (Dependent)
        Done
        AnalysisNames
    end
        
    methods
        function obj = axlTest(varargin)
        % create a new axlTest object
        %
        % USE
        %  obj = cdsOutCorners(Corner,Result,...)
        %
        % INPUTS
        %  Corner - First corner for this test [cdsOutCorner](optional)
        %  Result - Cadence run for this test [cdsOutRun](optional)
        % PARAMETERS
        %  signals - defines the signals to save
        %  transientSignals - defines the signals to save only for a
        %   transient analysis
        %  dcSignals - defines the signals to save only for a
        %   dc analysis
        %  desktop - Opens a new desktop if one isn't open yet (logical)
        %
        % See also: cdsOutCorner, cdsOutTest, cdsOutRun
        
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
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('corner',cdsOutCorner.empty,@(x) isa(x,'cdsOutCorner'));
            p.addOptional('Result',cdsOutRun.empty,@(x) isa(x,'cdsOutRun'));
            p.parse(varargin{:});
            obj.CornerDoneCnt = 0;
            
            % Add first corner
            obj.Corners = cdsOutCorner.empty;
            obj.Analyses = struct;
            obj.Analyses.stb = Analyses.STB;
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
            if(~isa(val,'cdsOutCorner'))
                error('VirtuosoToolbox:cdsOutTest:addCorner','corner must be a cdsOutCorner');
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
    end
    
end

