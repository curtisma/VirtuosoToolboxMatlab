classdef cdsOutRun < cdsOut
    %cdsOutRun Cadence Simulation run results
    %   Collects the data from a single Cadence simulation run.
    %
    % USAGE
    %  cdsOutMatlab(axlCurrentResultsPath,...)
    %
    % INPUTS
    %
    %
    properties
        tests
        names
        paths
        process
    end
    properties (Transient)
        cornerDoneCnt
    end
    properties (Dependent)
        simDone
    end
    
    methods
        function obj = cdsOutRun(varargin)
        % cdsOutRun A single simulation run
        %
        % USE
        %  obj = cdsOutRun(axlCurrentResultsPath,...)
        %  obj = cdsOutRun(corner,...)
        %  obj = cdsOutRun(test,...)
        %  obj = cdsOutRun
        %
        % INPUTS
        %  test- cdsOutTest object or path to test data directory as a char
        % Parameters
        %  signals 
        %  transientSignals
        %  dcSingals -
        %  process - process specific information
        
%             obj = obj@cdsOut(varargin{:}); % Superclass constructor
            p = inputParser;
            %p.KeepUnmatched = true;
            p.addOptional('data',cdsOutTest.empty,@(x) ischar(x) || isa(x,'cdsOutCorner') || isa(x,'cdsOutTest'));
            p.addParameter('signals',[],@iscell);
            p.addParameter('transientSignals',[],@iscell);
            p.addParameter('dcSignals',[],@iscell);
            p.addParameter('desktop',false,@islogical);
            p.addParameter('process',processes.GENERIC.empty);
            p.addParameter('loadData',false,@islogical)
            p.parse(varargin{:});
            
            % Load a full result if using the loadData option
            if(p.Results.loadData && ~isempty(p.Results.data))
            	obj.loadData(varargin{:})
            % Normal corner path
            elseif(ischar(p.Results.data) || isa(p.Results.data,'cdsOutCorner'))
                if(nargin>1)
                    corner = obj.addCorner(p.Results.data,varargin{2:end});
                else
                    corner = obj.addCorner(p.Results.data);
                end
                corner.results = obj;
            elseif(isa(p.Results.data,'cdsOutTest'))
%                 obj.paths.test = p.Results.data;
                obj.tests = cdsOutTest.empty;
            else
                obj.tests = cdsOutTest.empty;
            end
            obj.cornerDoneCnt = 0;
            if(exist('corner','var') && isempty(corner.process))
                obj.process = p.Results.process;
            end
        end
        function corner = addCorner(obj,corner,varargin)
            corner = addCorner@cdsOut(obj,corner,varargin{:});
            % Check that the corner corresponds to this run 
            if(isempty(obj.tests) && ~isempty(corner))
            % initialize run with the properties of the given corner
                obj.Name = corner.names.result;
                obj.names.library = corner.names.library;
                corner.result = obj;
            elseif(~isempty(obj.tests) && ~isempty(corner))
                if(~strcmp(obj.Name, corner.names.result))
                % Check that this corner is for this run
                    error('VirtuosoToolbox:cdsOutTest:setCorners','Wrong test name');
                end
            end
            % Find the corner's test or start a new one
            selTest = strcmp({obj.tests.Name},corner.names.test);
            if(isempty(selTest)||~any(selTest))
                obj.tests(end+1) = cdsOutTest(corner,varargin{:});
            elseif(sum(selTest)==1)
                obj.tests(selTest).addCorner(corner,varargin{:});
            else
                error('VirtuosoToolbox:cdsOutTest:setCorners','Multiple test matches found');
            end
            obj.process = corner.process;
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
        function parsePath(obj)
            obj.paths.project = char(strjoin({'','prj',obj.names.project},filesep));
            obj.paths.doc = fullfile(obj.paths.project,'doc');
            obj.paths.matlab = fullfile(obj.paths.doc,'matlab');
            obj.paths.runData = char(strjoin(obj.paths.psfLocFolders(1:11),filesep));
            
            obj.names.user = psfLocFolders{4};
            obj.names.library = psfLocFolders{5};
            inUserLib = find(strcmp('adexl',psfLocFolders)) == 8;
            if(inUserLib)
                obj.names.userLibrary = psfLocFolders{6};
            end
            obj.names.testBenchCell = psfLocFolders{6+inUserLib};
            obj.names.result = psfLocFolders{10+inUserLib};
            
%             obj.names.test = psfLocFolders{12+inUserLib};
%             obj.paths.testData = 
        end
        function val = get.simDone(obj)
            if(isempty(obj.tests))
                val = false;
            else
                % Check to make sure all the runs are complete
                val = all(obj.tests.simDone);
            end
        end
        function set.tests(obj,val)
            if(isempty(obj.tests) && ~isempty(val))
                obj.Name = val.names.result;
            end
            obj.tests = val;
            % initialize cdsOutMatlab with the
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
        function varargout = subsref(obj,s)
        % subsref Provides customized indexing into the results property
        %
        % See also: cdsOutMatlab, cdsOutMatlab/numArgumentsFromSubscript
            if(length(s)>=2 && strcmp(s(1).type,'.') && strcmp(s(1).subs,'tests'))
                switch s(2).type
                    case {'{}' '()'}
                        if(iscell(s(2).subs))
                            resultIdx = strcmp(s(2).subs{1},obj.tests.Name);
                            if(any(resultIdx))
                                if(length(s) == 2)
                                    varargout = {obj.tests(resultIdx)};
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
            if(length(s)>=2 && strcmp(s(1).type,'.') && strcmp(s(1).subs,'tests'))
                varargout = {1};
            else
                varargout = {builtin('numArgumentsFromSubscript',obj,s,indexingContext)};
            end
        end
    end
    
end

