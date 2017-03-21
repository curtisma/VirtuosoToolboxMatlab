classdef cdsOutMatlab < cdsOut
    %cdsOutMatlab A Cadence Matlab output script
    %   Creates a cadence MATLAB output script to handle the collection and 
    %   of Cadence simulation results using MATLAB
    %
    % USAGE
    %  cdsOutMatlab(axlCurrentResultsPath,...)
    %  cdsOutMatlab(
    %
    %
    % See also: cdsOutMatlab/cdsOutMatlab, cdsOutMatlab/save,
    % cdsOutMatlab.load, cdsOutCorner, cdsOutRun,cdsOutTest
    
    
    properties
        results
        names
        paths
        runHistoryLength
    end
    properties (Transient = true)
        filepath
        currentResult
        currentTest
        currentCorner
        simDone
    end
    properties (Dependent)
        CR
    end
    methods
        function obj = cdsOutMatlab(varargin)
        %cdsOutMatlab Creates a new matlab output saving script
            obj = obj@cdsOut(varargin{:}); % Superclass constructor
%             if((nargin > 0) && ischar(varargin{1}))
%                 obj.paths.psfLocFolders = strsplit(varargin{1},filesep);
%                 if(isunix && isdir(varargin{1}))
%                     obj.getNames(obj.paths.psfLocFolders);
%                     obj.getPaths;
%                     obj.Info.who = who;
%                 end
%             end
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('axlCurrentResultsPath','',@(x) ischar(x) && isdir(x));
            p.addParameter('signals',[],@iscell);
            p.addParameter('transientSignals',[],@iscell);
            p.addParameter('dcSignals',[],@iscell);
            p.addParameter('filepath',[],@ischar);
            p.addParameter('runHistoryLength',10,@isdouble)
            p.addParameter('loadData',false,@islogical)
            p.parse(varargin{:});
%             if(~isempty(p.Results.DUT))
%                 obj.filepath p.Results.DUT
%             else
                obj.filepath = p.Results.filepath;
%             end
            obj.runHistoryLength = p.Results.runHistoryLength;
            obj.results = cdsOutRun.empty;
            
            % Load a full result if using the loadData option
            if(p.Results.loadData && ~isempty(p.Results.axlCurrentResultsPath))
            	obj.loadData(varargin{:})
            % Normal corner path
            elseif(~isempty(p.Results.axlCurrentResultsPath))
                obj.currentCorner = cdsOutCorner(varargin{:});
                if(nargin>1)
                    obj.addCorner(obj.currentCorner,varargin{2:end});
                else
                    obj.addCorner(obj.currentCorner);
                end
            end
        end
        function addCorner(obj,corner,varargin)
        	corner = addCorner@cdsOut(obj,corner,varargin{:});
            if(~isempty(obj.results))
                resultIdx = strcmp({obj.results.Name},corner.names.result);
                resultNames = obj.results.names;
                libIdx = strcmp({resultNames.library},corner.names.library);
                if(~any(resultIdx & libIdx))
                    result = obj.addResult;
                elseif(sum(resultIdx & libIdx) == 1)
                    result = obj.results(resultIdx & libIdx);
                else
                    error('VirtuosoToolbox:cdsOutTest:addCorner','corner belongs to multiple results');
                end
            else
                result = obj.addResult;
            end
            result.addCorner(corner,varargin{:});
        end
        function result = addResult(obj,varargin)
%             if(ischar(resultIn))
%                 resultIn = cdsOutRun();
%             elseif(isa(resultIn,'cdsOutRun'))
%                 resultIn = 1;
%             end
%             resultIdx = strcmp(resultIn.Name,{obj.results.Name});
%             if(isempty(resultIdx))
            % Create new result
                if(length(obj.results) < obj.runHistoryLength)
                    result = cdsOutRun;
                    obj.results(end+1) = result;
                else
                    result = cdsOutRun;
                    obj.results = [obj.result(2:end-1) result];
                end
%             elseif(length(resultIdx) == 1)
            % Replace existing result
%                 obj.result(resultIdx) = resultIn;
%             else
%                 warning('VirtuosoToolbox:cdsOutMatlab:addResult','Duplicate results exist');
%             end
        end
        function save(obj,varargin)
        % Save Saves the cdsOutMatlab dataset to a file
        %   The dataset is saved to a mat file
        %
        % USAGE
        %  MAT.save;
        %   saves the obj to a file
        %  data = MAT.save(filePath)
        % INPUTS
        %  filePath - file path to save the file. (optional) 
        %  If unspecified the dataset's current filePath is used.
        %  If specified the dataset's filepath property is set to filePath
        % OUTPUTS
        %  data - saved dataset table
        % see also: cdsOutMatlab
            p = inputParser;
            p.addOptional('filePath', [], @(x) ischar(x) || isempty(x));
            p.addParameter('saveMode','append',@ischar);
            p.parse(varargin{:});
            
            if(~isempty(p.Results.filePath))
                obj.filepath = p.Results.filePath;
                filePath = p.Results.filePath;
            elseif(~isempty({obj.filePath}))
                filePath = obj.filepath;
            else
                filePath = [];
            end
                        
            if(isempty(filePath) && ispc)
                [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'; ...
                	'*.*',  'All Files (*.*)'},'Select file to save data');
                if isequal(filename,0) || isequal(pathname,0)
                    disp('User pressed cancel')
                    return;
                else
                    obj.filepath = fullfile(pathname,filename);
                end
            end
            
            % Save
            save(obj.filepath,'obj');
        end
        function loadData(obj,varargin)
        % loadData Loads data from the Cadence database using MATLAB.
        %  Results are unique according to their library and result names.
        %  
        % USAGE
        %  obj.loadData(resultDir,...)
        % INPUTS
        %  resultsDir - results directory containing a numbered folder for
        %               each corner sim number and a psf directory
        % Parameters
        %  Any cdsOutCorner parameters
        %
        % See also: cdsOutCorner
            resultDir = dir(varargin{1});
            resultDir = str2double({resultDir.name});
            resultDir = resultDir(~isnan(resultDir));
            if(isempty(resultDir))
                warning(['Data unavailable for:' varargin{1}]);
            end
%             out = cdsOutMatlab.empty;
            for cornerNum = 1:length(resultDir)
                testName = dir(fullfile(varargin{1},num2str(resultDir(cornerNum))));
                testName = {testName.name};
                testName = testName(3:end);
                for testNum = 1:length(testName)
                    cornerPSFpath = fullfile(varargin{1},num2str(resultDir(cornerNum)),testName{testNum},'psf');
                    if(nargin ==1)
                        obj.addCorner(cornerPSFpath);
                    elseif(nargin >1)
                        obj.addCorner(cornerPSFpath,varargin{2:end});
                    end
                end
            end
        end
        function getPaths(obj)
            obj.paths.project = char(strjoin({'','prj',obj.names.project},filesep));
            obj.paths.doc = fullfile(obj.paths.project,'doc');
            obj.paths.matlab = fullfile(obj.paths.doc,'matlab');
            obj.paths.runData = char(strjoin(obj.paths.psfLocFolders(1:11),filesep));
%             obj.paths.testData = 
        end
        function val = get.names(obj)
            if(~isempty(obj.results))
                val = obj.names;
%                 val.lol = unique({obj.runs})
            else
                val = struct;
            end
        end
        function val = get.simDone(obj)
            if(isempty(obj.results))
                val = false;
            else
                % Check to make sure all the runs are complete
                val = all([obj.results.simDone]);
            end
        end
        function result = get.CR(obj)
            if(~isempty(obj.currentResult))
                result = obj.currentResult;
            elseif(~isempty(obj.results))
                result = obj.results(end);
            else
                result = cdsOutRun.empty;
            end
        end
        function varargout = subsref(obj,s)
        % subsref Provides customized indexing into the results property
        %
        % See also: cdsOutMatlab, cdsOutMatlab/numArgumentsFromSubscript
            if(length(s)>=2 && strcmp(s(1).type,'.') && strcmp(s(1).subs,'results'))
                switch s(2).type
                    case {'{}' '()'}
                        if(iscell(s(2).subs))
                            resultIdx = strcmp(s(2).subs{1},obj.results.Name);
                            if(any(resultIdx))
                                if(length(s) == 2)
                                    varargout = {obj.results(resultIdx)};
                                else
                                    varargout = {builtin('subsref',obj,s)};
                                end
                            else
                                warning('Result not found')
                                varargout = {cdsOutRun.empty};
                            end
                        else
                            varargout = {obj.results.subsref(obj.results,s(2:end))};
                        end
                    case '.'
                        varargout = {builtin('subsref',obj,s)};
                end
            elseif(any(strcmp(s(1).subs,methods(obj))))
                if(nargout == 0)
                    builtin('subsref',obj,s);
                else
                    varargout = {builtin('subsref',obj,s)};
                end
            else
                varargout = {builtin('subsref',obj,s)};
            end
        end
        function varargout = numArgumentsFromSubscript(obj,s,indexingContext)
            if(length(s)>=2 && strcmp(s(1).type,'.') && strcmp(s(1).subs,'results'))
                varargout = {1};
            else
                varargout = {builtin('numArgumentsFromSubscript',obj,s,indexingContext)};
            end
        end
    end
    methods (Static)
        
        function data = load(varargin)
        %load Loads a saved datafile
        %
        % USAGE
        %  data = cdsOutMatlab.load(filePath);
        %
        % see also: cdsOutMatlab/save
        % USAGE
        %  data = cdsOutMatlab.load(filePath);
        % INPUTS
        %  filePath - a single file path or a cell array of paths to load
        % Outputs
        %  data - dataset table containing the following columns: data, 
        %   library name, test bench cell name (TBcell), test name, and 
        %   result name.
        %
        % see also: cdsOutMatlab/save
            p = inputParser;
            p.addOptional('filepath',[],@(x) ischar(x) || iscell(x));
%             p.addParameter('tableOut',false,@islogical);
            p.parse(varargin{:});
            if(isempty(p.Results.filepath))
                [filename, pathname] = uigetfile({'*.mat','MAT-files (*.mat)'; ...
                	'*.*',  'All Files (*.*)'},'Select file to save data',...
                    'MultiSelect', 'on');
                if isequal(filename,0) || isequal(pathname,0)
                    disp('User pressed cancel')
                    return;
                else
                    if(iscell(filename))
                        cellfun(@(x,y) fullfile(x,y),pathname,filename);
                    else
                        filePath = fullfile(pathname,filename);
                    end
                end
            else
                filePath = p.Results.filepath;
            end
            if(ischar(filePath))
                data = load(filePath);
                data = data.obj;
            elseif(iscell(filePath))
                data = cdsOutMatlab.empty;
                for fileIdx = 1:length(filePath)
                    dataIn = load(filePath{fileIdx});
                    data = [data dataIn.obj];
                end
            else
                data = cdsOutMatlab.empty;
            end
%             library = {};
%             result = {};
%             cell = {};
%             test = {};
%             libs = fieldnames(MAT);
%             for libIdx = 1:length(libs)
%                 testBenches = fieldnames(MAT.(libs{libIdx}));
%                 for testBenchIdx = 1:length(testBenches)
%                     tests = fieldnames(MAT.(libs{libIdx}).(testBenches{testBenchIdx}));
%                     for testIdx = 1:length(tests)
%                         res = fieldnames(MAT.(libs{libIdx}).(testBenches{testBenchIdx}).(tests{testIdx}));
%                         [result{end+1:end+length(res)}] = deal(char(res));
%                         [library{end+1:end+length(res)}] = deal(char(libs{libIdx}));
%                         [cell{end+1:end+length(res)}] = deal(char(testBenches{testBenchIdx}));
%                         [test{end+1:end+length(res)}] = deal(char(tests{testIdx}));
%                         data = struct2cell(MAT.(libs{libIdx}).(testBenches{testBenchIdx}).(test{testIdx}));
%                         data = [data{:}];
%                     end
%                 end
%             end
%             switch nargout
%                 case {0,1}
%                     if(p.Results.tableOut)
%                         varargout = {table(data, library', cell', test', result')};
%                         varargout{1}.Properties.VariableNames = {'data', 'library', 'cell', 'test', 'result'};
%                     else
%                         varargout = {data};
%                     end
%                 case 2
%                     varargout = {data result};
%                 case 3
%                     varargout = {data test result};
%                 case 4
%                     varargout = {data cell test result};
%                 case 5
%                     varargout = {data library cell test result};
%                 otherwise
%                     error('skyVer:cdsOutMatlab:load','Wrong number of outputs');
%             end
        end
    end
end

