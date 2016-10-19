classdef cdsOutRun < cdsOut
    %cdsOutRun Cadence Simulation run results
    %   Collects the data from a single Cadence simulation run.
    
    properties
        tests
        script
        names
        paths
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
        %  obj = cdsOutRun(test,...)
        %
        % INPUTS
        %  test- cdsOutTest object or path to test data directory as a char
        % Parameters
        %  
        %
%             obj = obj@cdsOut(varargin{:}); % Superclass constructor
            p = inputParser;
            %p.KeepUnmatched = true;
            p.addOptional('data',cdsOutTest.empty,@(x) ischar(x) || isa(x,'cdsOutCorner') || isa(x,'cdsOutTest'));
            p.addParameter('signals',[],@iscell);
            p.addParameter('transientSignals',[],@iscell);
            p.addParameter('dcSignals',[],@iscell);
            p.addParameter('desktop',false,@islogical);
            p.parse(varargin{:});
            if(ischar(p.Results.data) || isa(p.Results.data,'cdsOutCorner'))
                if(nargin>1)
                    obj.addCorner(p.Results.data,varargin{2:end});
                else
                    obj.addCorner(p.Results.data);
                end
            elseif(isa(p.Results.data,'cdsOutTest'))
%                 obj.paths.test = p.Results.data;
                obj.tests = cdsOutTest.empty;
            else
                obj.tests = cdsOutTest.empty;
            end
            obj.cornerDoneCnt = 0;
        end
        function addCorner(obj,corner,varargin)
            if(ischar(corner))
            % Initialize corner
                corner = cdsOutCorner(corner);
            end
            if(~isa(corner,'cdsOutCorner'))
                error('VirtuosoToolbox:cdsOutTest:addCorner','corner must be a cdsOutCorner');
            end
            % Check that the corner corresponds to this run 
            if(isempty(obj.tests) && ~isempty(corner))
            % initialize run with the properties of the given corner
                obj.name = corner.names.result;
                obj.names.library = corner.names.library;
                corner.result = obj;
            elseif(~isempty(obj.tests) && ~isempty(corner))
                if(~strcmp(obj.name, corner.names.result))
                % Check that this corner is for this run
                    error('VirtuosoToolbox:cdsOutTest:setCorners','Wrong test name');
                end
            end
            % Find the corner's test or start a new one
            selTest = strcmp({obj.tests.name},corner.names.test);
            if(isempty(selTest))
                obj.tests(end+1) = cdsOutTest(corner,varargin{:});
            elseif(sum(selTest)==1)
                obj.tests(selTest).addCorner(corner,varargin{:});
            else
                error('VirtuosoToolbox:cdsOutTest:setCorners','Multiple test matches found');
            end
                    
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
                obj.name = val.names.result;
            end
            obj.tests = val;
            % initialize cdsOutMatlab with the
        end
    end
    
end

