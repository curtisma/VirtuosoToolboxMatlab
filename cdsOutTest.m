classdef cdsOutTest < cdsOut
    %cdsOutRun Cadence Simulation run results
    %   Collects the data from a single Cadence test
    
    properties
        analyses
        corners % An array of cdsOutCorners arranged by simNum
        cornernames
        run
        names
        paths
        process
    end
    properties (Transient)
        cornerDoneCnt
    end
    properties (Dependent)
        Done
        analysisNames
    end
        
    methods
        function obj = cdsOutTest(varargin)
        % create a new cdsOutCorner object
        %
        % USE
        %  obj = cdsOutCorners(run, corner ...)
        %
        % INPUTS
        %  run - Cadence run for this test [cdsOutRun](optional)
        %  corner - First corner for this test [cdsOutCorner](optional)
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
            p.addOptional('run',cdsOutRun.empty,@(x) isa(x,'cdsOutRun'));
            p.parse(varargin{:});
            obj.cornerDoneCnt = 0;
            
            % Add first corner
            obj.corners = cdsOutCorner.empty;
            obj.analyses = struct;
            obj.analyses.stb = analyses.STB;
            if(~isempty(p.Results.corner))
                if(nargin >1)
                    obj.addCorner(p.Results.corner,varargin{2:end});
                else
                    obj.addCorner(p.Results.corner);
                end
                
            end
        end
        function set.corners(obj,val)
%             if(~isempty(val))
% %                 if(~strcmp(obj.name, val.names.test))
% %                 % Check that this corner is for this test
% %                     error('VirtuosoToolbox:cdsOutTest:setCorners','Wrong test name');
% %                 end
%                 val.test = obj;
%             end
            if(~isa(val,'cdsOutCorner'))
                error('VirtuosoToolbox:cdsOutTest:addCorner','corner must be a cdsOutCorner');
            end
            obj.corners = val;
%             if(exist('obj.Info.corner','var') && isempty(obj.Info.corner))
%                 obj.getCornerList;
%             end
        end
        function addCorner(obj,corner,varargin)
            corner = addCorner@cdsOut(obj,corner,varargin{:});
            if(isempty(obj.corners) && ~isempty(corner))
            % initialize test with the properties of the given corner
                obj.Name = corner.names.test;
                obj.names.result = corner.names.result;
                obj.names.library = corner.names.library;
            elseif(~isempty(obj.corners) && ~isempty(corner))
                if(~strcmp(obj.Name, corner.names.test))
                % Check that this corner is for this test
                    error('VirtuosoToolbox:cdsOutTest:setCorners','Wrong test name');
                end
            end
            corner.test = obj;
            obj.corners(corner.simNum) = corner;
            if(any(strcmp('stb-stb',corner.Info.availableAnalyses)))
                if(~any(strcmp('stb-margin.stb',corner.Info.availableAnalyses)))
                end
                obj.analyses.stb.loadData(corner);
            end
            obj.names = corner.names;
            obj.paths = corner.paths;
            obj.cornerDoneCnt = obj.cornerDoneCnt +1;
            obj.process = corner.process;
            if(isempty(obj.Info) || (isempty(obj.Info) && ~isfield(obj.Info,'cornerNames')))
                obj.getCornerList;
            end
            if(isfield(obj.Info,'cornerNames') && ~isempty(obj.Info.cornerNames))
                corner.Name = obj.Info.cornerNames{corner.simNum};
            end
        end
        function getAllPropertiesCorners(obj)
        % Corners psf properties
            obj.Info.corners.tranDatasets = cds_srr(obj.paths.psfPathCorners,'tran-tran');
            cornerProperties = obj.Info.corners.tranDatasets.prop;
            for i = 1:length(cornerProperties)
                obj.Info.corners.properties.(regexprep(cornerProperties{i},'\(|\)|\.| ','')) = ...
                cds_srr(obj.paths.psfPathCorners,'tran-tran',cornerProperties{i});
            end
        end
        function getCornerList(obj)
        % Corner Info
            if(~isempty(obj.corners))
                obj.paths.psfPathCorners = strjoin([obj.paths.psfLocFolders(1:11) 'psf' obj.paths.psfLocFolders(13) 'psf'],filesep);
                obj.paths.run = strjoin(obj.paths.psfLocFolders(1:11),filesep);
                obj.paths.psfTmp = strjoin([obj.paths.psfLocFolders(1:10) ['.tmpADEDir_' obj.names.user] obj.names.test [obj.names.library '_' obj.names.testBenchCell '_' obj.names.cellView '_spectre'] 'psf'],filesep);
                psfPathCornersContents = dir(obj.paths.psfPathCorners);
                if(length({psfPathCornersContents.name}) > 2)
                    obj.paths.runObjFile = strjoin({obj.paths.psfPathCorners 'runObjFile'},filesep);
                else
                    obj.paths.runObjFile = strjoin({obj.paths.psfTmp 'runObjFile'},filesep);
                end
                obj.Info.runObjFile = cdsOutMatlab.loadTextFile(obj.paths.runObjFile);
                if(isempty(obj.Info.runObjFile))
                    obj.dir(obj.paths.runObjFile);
                    disp(obj.Info.dir.(obj.paths.runObjFile).Names);
                    disp(obj.paths.runObjFile);
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
%                 obj.names.corner = obj.Info.cornerNames{obj.simNum};
%                 obj.getCornerInfo;
            end
        end
        function getPaths(obj)
            obj.paths.project = char(strjoin({'','prj',obj.names.project},filesep));
            obj.paths.doc = fullfile(obj.paths.project,'doc');
            obj.paths.matlab = fullfile(obj.paths.doc,'matlab');
            obj.paths.result = char(strjoin(obj.paths.psfLocFolders(1:11),filesep));
%             obj.paths.testData = 
        end
        function val = get.Done(obj)
            if(isstruct(obj.Info) && isfield(obj.Info,'numCorners') && ~isempty(obj.corners))
                cornersAvailable = sum(cellfun(@(x) ~isempty(x),{obj.corners.simNum}));
                val = (cornersAvailable == obj.Info.numCorners);
            else
                val = false;
                warning('skyVer:cdsOutTest:get_Done','numCorners Unavailable');
            end
        end
        function val = get.analysisNames(obj)
            val = fieldnames(obj.corners(1).analyses);
        end
        function analysis = getAnalysis(obj,analysisName)
            analyses = [obj.corners.analyses];
        	analysis= [analyses.(analysisName)];
        end
        function dataTable = getDataTable(obj,varargin)
            dataTable = table([obj.corners.temp]',{obj.corners.processCorner}');
            dataTable.Properties.VariableNames = {'temp', 'process'};
            dataTable.Properties.DimensionNames = {'Corner','Variables'};
            vars = [obj.corners.variables];
            if(~isempty(obj.process))
                variableNames = setdiff(fieldnames(vars),[obj.process.variableNames {'temp'}]);
            else
                variableNames = fieldnames(vars);
            end
            varVal = struct;
            for varIdx = 1:length(variableNames)
                varVal.(variableNames{varIdx}) = [vars.(variableNames{varIdx})]';
            end
            dataTable = [dataTable struct2table(varVal)];
            dataTable.Properties.RowNames = {obj.corners.Name};
        end
        function set.process(obj,val)
            if(ischar(val))
                val = processes.(val);
            end
            if(~isa(val,'cdsProcess'))
                error('VirtuosoToolbox:cdsOutRun:setProcess','Process must be subclassed from cdsProcess')
            end
            obj.process = val;
        end
    end
    
end

