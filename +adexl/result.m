classdef result < adexl.resultsInterface
    %result Cadence Simulation run result
    %   Collects the data from a single Cadence simulation run.
    %
    % USAGE
    %  runObj = adexl.result(data,...)
    %
    %  runObj = adexl.result(axlCurrentResultsPath,...)
    %  runObj = adexl.result(corner,...)
    %  runObj = adexl.result(test,...)
    % INPUTS
    %  data- adexl.test or adexl.corner object or path to test data directory as a char
    % Parameters
    %  signals - 
    %  transientSignals - 
    %  dcSingals - 
    %  Process - process specific information
    %
    properties
        Tests
        Names
        Paths
        Process
    end
    properties (Transient)
        cornerDoneCnt
    end
    properties (Dependent)
        Done
    end
    
    methods
        function obj = result(varargin)
        % result A single simulation run
        %   See class description for usage information.
        %
        % See also: adexl.result
        
            obj = obj@adexl.resultsInterface(varargin{:}); % Superclass constructor
            p = inputParser;
            %p.KeepUnmatched = true;
            p.addOptional('data',adexl.test.empty,@(x) ischar(x) || isa(x,'adexl.corner') || isa(x,'adexl.test'));
            p.addParameter('signals',[],@iscell);
            p.addParameter('transientSignals',[],@iscell);
            p.addParameter('dcSignals',[],@iscell);
            p.addParameter('Process',processes.GENERIC.empty);
            p.parse(varargin{:});
            
            % Load a full result if a results dir is provided
            if(ischar(p.Results.data) && adexl.result.isResultFolder(p.Results.data))
                obj.Tests = adexl.test.empty;
            	obj.loadData(varargin{:})
            % Normal corner path
            elseif(ischar(p.Results.data) || isa(p.Results.data,'adexl.corner'))
                obj.startLog(p.Results.data);
                if(nargin>1)
                    corner = obj.addCorner(p.Results.data,varargin{2:end});
                else
                    corner = obj.addCorner(p.Results.data);
                end
                corner.result = obj;
            elseif(isa(p.Results.data,'adexl.test'))
%                 obj.Paths.test = 
                obj.Tests(end+1) = p.Results.data;
            else
                obj.Tests = adexl.test.empty;
            end
            obj.cornerDoneCnt = 0;
            if(exist('corner','var') && isempty(corner.Process))
                obj.Process = p.Results.Process;
            end
        end
        function corner = addCorner(obj,corner,varargin)
            corner = addCorner@resultInterface(obj,corner,varargin{:});
            % Check that the corner corresponds to this run 
            if(isempty(obj.Tests) && ~isempty(corner))
            % initialize run with the properties of the given corner
                obj.Name = corner.Names.result;
                obj.Names.library = corner.Names.library;
                corner.result = obj;
            elseif(~isempty(obj.Tests) && ~isempty(corner))
                if(~strcmp(obj.Name, corner.Names.result))
                % Check that this corner is for this run
                    error('VirtuosoToolbox:adexl_test:setCorners','Wrong test name');
                end
            end
            % Find the corner's test or start a new one
            if(~isempty(obj.Tests))
                selTest = strcmp({obj.Tests.Name},corner.Names.test);
            else
                selTest = [];
                obj.Tests = adexl.test.empty;
            end
            if(isempty(selTest)||~any(selTest))
                obj.Tests(end+1) = adexl.test(corner,varargin{:});
            elseif(sum(selTest)==1)
                obj.Tests(selTest).addCorner(corner,varargin{:});
            else
                error('VirtuosoToolbox:adexl_test:setCorners','Multiple test matches found');
            end
            obj.Process = corner.Process;
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
        %  Any adexl.corner parameters
        %
        % See also: adexl.corner
            resultDir = dir(varargin{1});
            resultDir = str2double({resultDir.name});
            resultDir = resultDir(~isnan(resultDir));
            if(isempty(resultDir))
                warning(['Data unavailable for:' varargin{1}]);
            end
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
        function parsePath(obj)
            obj.Paths.project = char(strjoin({'','prj',obj.Names.project},filesep));
            obj.Paths.doc = fullfile(obj.Paths.project,'doc');
            obj.Paths.matlab = fullfile(obj.Paths.doc,'matlab');
            obj.Paths.runData = char(strjoin(obj.Paths.psfLocFolders(1:11),filesep));
            
            obj.Names.user = psfLocFolders{4};
            obj.Names.library = psfLocFolders{5};
            inUserLib = find(strcmp('adexl',psfLocFolders)) == 8;
            if(inUserLib)
                obj.Names.userLibrary = psfLocFolders{6};
            end
            obj.Names.testBenchCell = psfLocFolders{6+inUserLib};
            obj.Names.result = psfLocFolders{10+inUserLib};
            
%             obj.Names.test = psfLocFolders{12+inUserLib};
%             obj.Paths.testData = 
        end
        function val = get.Done(obj)
            if(isempty(obj.Tests))
                val = false;
            else
                % Check to make sure all the runs are complete
                val = all(obj.Tests.Done);
            end
        end
        function set.Tests(obj,val)
            if(isempty(obj.Tests) && ~isempty(val))
                obj.Name = val.Names.result;
            end
            obj.Tests = val;
        end
        function set.Process(obj,val)
            if(ischar(val))
                val = processes.(val);
            end
            if(~isa(val,'cdsProcess'))
                error('VirtuosoToolbox:adexl_result:setProcess','Process must be subclassed from cdsProcess')
            end
            obj.Process = val;
        end
        function varargout = subsref(obj,s)
        % subsref Provides customized indexing into the results property
        %
        % See also: adexl.result, adexl.result/numArgumentsFromSubscript
            if(length(s)>=2 && strcmp(s(1).type,'.') && strcmp(s(1).subs,'Tests'))
                switch s(2).type
                    case {'{}' '()'}
                        if(iscell(s(2).subs))
                            resultIdx = strcmp(s(2).subs{1},obj.Tests.Name);
                            if(any(resultIdx))
                                if(length(s) == 2)
                                    varargout = {obj.Tests(resultIdx)};
                                else
                                    varargout = {builtin('subsref',obj,s)};
                                end
                            else
                                warning('Result not found')
                                varargout = {adexl.result.empty};
                            end
                        else
                            varargout = {obj.results.subsref(obj.results,s(2:end))};
                        end
                    case '.'
                        varargout = {builtin('subsref',obj,s)};
                end
            elseif(any(strcmp(s(1).subs,methods(obj))))
                if(strcmp(s(1).subs,'subsref'))
                    varargout = {obj.subsref(obj,s(2:end))};
                elseif(nargout == 0)
                    builtin('subsref',obj,s);
                else
                    varargout = {builtin('subsref',obj,s)};
                end
            else
                varargout = {builtin('subsref',obj,s)};
            end
        end
        function varargout = numArgumentsFromSubscript(obj,s,indexingContext)
            if(length(s)>=2 && strcmp(s(1).type,'.') && strcmp(s(1).subs,'Tests'))
                varargout = {1};
            else
                varargout = {builtin('numArgumentsFromSubscript',obj,s,indexingContext)};
            end
        end
    end
    
end

