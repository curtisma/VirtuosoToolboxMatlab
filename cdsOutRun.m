classdef cdsOutRun < cdsOut
    %cdsOutRun Cadence Simulation run results
    %   Collects the data from a single Cadence simulation run.
    
    properties
        tests
        script
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
            p.addParameter('process',cdsProcess.empty);
            p.parse(varargin{:});
            
            if(ischar(p.Results.data) || isa(p.Results.data,'cdsOutCorner'))
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
            if(isempty(selTest)||~any(selTest))
                obj.tests(end+1) = cdsOutTest(corner,varargin{:});
            elseif(sum(selTest)==1)
                obj.tests(selTest).addCorner(corner,varargin{:});
            else
                error('VirtuosoToolbox:cdsOutTest:setCorners','Multiple test matches found');
            end
            obj.process = corner.process;
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
        function set.process(obj,val)
            if(ischar(val))
                val = processes.(val);
            end
            if(~isa(val,'cdsProcess'))
                error('VirtuosoToolbox:cdsOutRun:setProcess','Process must be subclassed from cdsProcess')
            end
            obj.process = val;
        end
%         function varargout = subsref(obj,s)
%         % Provides customized indexing into an array of objects
%         %
%         % moved from cdsOutRun.m
% %         if(~isa(obj)
%             switch s(1).type
%                 case {'{}' '()'}
%                     if(iscell(s(1).subs) && ischar(s(1).subs{1}))
%                         s(1).subs = {strcmp(s(1).subs,{obj.name})};
%                         s(1).type = '()';
%                     end
%                     varargout = {builtin('subsref',obj,s)};
%                 otherwise
%                     varargout = {builtin('subsref',obj,s)};
%             end	
%         end
%         function varargout = numArgumentsFromSubscript(obj,s,indexingContext)
%             if(strcmp('{}',s(1).type) && iscell(s(1).subs(1)) && ischar(s(1).subs{1}))
%                 varargout = {1};
%             else
%                 varargout = {builtin('numArgumentsFromSubscript',obj,s,indexingContext)};
%             end
%         end
    end
    
end

