classdef corner < adexl.resultsInterface
    %corner Cadence Simulation run results
    %   Collects the data from a single Cadence simulation corner.
    % 
    % USE
    %  obj = adexl.corner(axlCurrentResultsPath, ...)
    % PARAMETERS
    %  signals - defines the signals to save
    %  transientSignals - defines the signals to save only for a
    %   transient analysis
    %  dcSignals - defines the signals to save only for a
    %   dc analysis
    %  desktop - Opens a new desktop if one isn't open yet (logical)
    % PARAMETERS & PROPERTIES
    %  Name - Name of the corner [char]
    %  ProcessCorner - Name of the current process corner [char]
    %  Temp - Temperature [numerical]
    %  Variables - Other Variables to be varied [adexl.variables]
    %  Test - The tests enabled for this corner [adexl.test]
    % See Also: adexl.test, adexl.cellview, adexl.result, adexl.cornerSet
    properties
        SimNum
        Analyses
        Temp
        ProcessCorner
        Variables % sim variable values
        Netlist
        Names
        Paths
        test
        Result
        Process
        signals
        Description
    end
    properties (Dependent)
    end
    properties (Access = private,Constant,Hidden)
        analysisTypes = {'tran-tran','stb-stb','stb-margin.stb','dcOp-dc','dc-dc','ac-ac'};
    end
    
    methods
        function obj = corner(varargin)
        %corner Create a new adexl.corner object
        %
        % See also: adexl.corner
            obj = obj@adexl.resultsInterface(varargin{1:end}); % Superclass constructor
            
            % Basic Information and log
            if(nargin>=1 && ~isempty(varargin{1}))
                obj.Paths.psf = char(varargin{1});
                obj.Paths.psfLocFolders = strsplit(varargin{1},filesep);
                obj.getNames(obj.Paths.psfLocFolders);
                obj.getPaths;
                obj.SimNum = str2double(obj.Paths.psfLocFolders{12});
            end
            % Parse Inputs
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('axlCurrentResultsPath','',@ischar);
            p.addParameter('signals',{},@iscell);
            p.addParameter('transientSignals',{},@iscell);
            p.addParameter('dcSignals',{},@iscell);
            p.addParameter('desktop',false,@islogical);
            p.addParameter('Process',processes.GENERIC.empty);
            % Setup Parameters
            p.addParameter('Name','',@ischar);
            p.addParameter('ProcessCorner','',@ischar);
            p.addParameter('Temp',[],@isnumeric);
            p.addParameter('Variables',adexl.variables.empty,@(x) isa(x,'adexl.variables'));
            p.addParameter('Test',adexl.test.empty,@(x) isa(x,'adexl.test'));
%             p.addParameter('test',@islogical);
            p.parse(varargin{:});
            obj.Process = p.Results.Process;
%             if(~isempty(p.Results.transientSignals))
%                 obj.Analyses.transient.waveformsList = p.Results.transientSignals;
%             elseif(~isempty(p.Results.signals))
%                 obj.Analyses.transient.waveformsList = p.Results.signals;
%             end
%             if(~isempty(p.Results.dcSignals))
%                 obj.Info.dc.signalList =
%                 obj.Info.dc.waveformsList = p.Results.dcSignals;
%             elseif(~isempty(p.Results.signals))
%                 obj.Info.dc.signalList
%                 obj.Info.dc.signalList = p.Results.signals;
%             end
            obj.signals = p.Results.signals;
            obj.Name = p.Results.Name;
            % Setup parameters
            obj.ProcessCorner = p.Results.ProcessCorner;
            obj.Temp = p.Results.Temp;
            obj.Variables = p.Results.Variables;
            % Get files
            if(nargin>=1 && ~isempty(varargin{1}))
                obj.getNetlist;
                obj.getSpectreLog;
                obj.getProcessCorner;
                if(isunix)
                    obj.loadAnalyses;
                    obj.Variables = adexl.variables;
%                     obj.Variables.import(obj.Paths.);
                    obj.Temp = obj.Variables.temp;
                end
                obj.Description = [obj.ProcessCorner '_' num2str(obj.Temp) 'c'];
            end
        end
        function signalOut = loadSignal(obj,analysis,signal)
        % Loads a signal from an analysis
        %
        % USE
        %  obj.loadSignal(analysis,signal)
        % INPUTS
        %  analysis - analysis to load signal from (Char)
        %  signal -  signal name (Char)
        %
        % See also: adexl.corner
            analysis = lower(analysis);
            switch analysis
                case {'transient','tran-tran','tran','trans'}
                    cdsAnalysisName = 'tran-tran';
                    analysis = 'transient';
                otherwise
                    warning('Wrong or unsupported analysis type');
            end
        	[~, signalOut] = evalc('cds_srr( obj.Paths.psf, cdsAnalysisName, signal)');
            obj.data.(analysis).(signal) = signalOut;
        end
        function getAnalysisProperties(obj,analysis)
        % get all the properties of an analysis
        %
        % USE
        %  obj.getAnalysisProperties(analysis);
        %   places the properties in the analysis's struct
        %
            [~,obj.Analyses.(obj.analysisName(analysis)).properties.list] = evalc('cds_srr(obj.Paths.psf,analysis)');
            properties = obj.Analyses.(obj.analysisName(analysis)).properties.list.prop;
            for i = 1:length(properties)
                [~,obj.Analyses.(obj.analysisName(analysis)).properties.(regexprep(properties{i},'\(|\)|\.| ',''))] = ...
                evalc('cds_srr(obj.Paths.psf,analysis,properties{i})');
            end
        end
        function getDatasetProperties(obj,dataset)
        % get all the properties of an analysis
        %
        % USE
        %  obj.getAnalysisProperties(analysis);
        %   places the properties in the analysis's struct
        %
            if(~isfield(obj.Info,'datasetProperties'))
                obj.Info.datasetProperties = struct;
            end
            if(~isfield(obj.Info.datasetProperties,dataset))
                obj.Info.datasetProperties.(datset) = struct;
            end
            [~,obj.Info.datsetProperties.(datset).list] = evalc('cds_srr(obj.Paths.psf,dataset)');
            properties = obj.Info.datsetProperties.(datset).list.prop;
            for i = 1:length(properties)
                [~,obj.Info.datsetProperties.(datset).(regexprep(properties{i},'\(|\)|\.| ',''))] = ...
                evalc('cds_srr(obj.Paths.psf,dataset,properties{i})');
            end
        end
        function loadAnalyses(obj)
        % Loads all analyses
%             obj.Info.datasets = cds_srr(obj.Paths.psf);
            [~,obj.Info.datasets] = evalc('cds_srr(obj.Paths.psf)');
            obj.Info.availableAnalyses = intersect(obj.Info.datasets,obj.analysisTypes);
%             if(any(strcmp('stb-stb',obj.Info.availableAnalyses)))
%                 obj.Analyses.stb = Analyses.STB(obj);
%             end
            if(any(strcmp(Analyses.DC.cdsName,obj.Info.availableAnalyses)))
                obj.Analyses.dc = Analyses.DC(obj,'signals',obj.signals);
            end
            if(any(strcmp('tran-tran',obj.Info.availableAnalyses)))
                obj.getDataTransient;
            end
            if(any(strcmp('dcOp-dc',obj.Info.availableAnalyses)))
                obj.getDataDCop;
            end
        end
        function getNames(obj,psfLocFolders)
            obj.Names.project = psfLocFolders{5};
            obj.Names.Result = psfLocFolders{11};
            obj.Names.user = psfLocFolders{4};
            obj.Names.library = psfLocFolders{6};
            obj.Names.adexlCell = psfLocFolders{7};
            obj.Names.test = psfLocFolders{13};
        end
        function getPaths(obj)
            obj.Paths.project = char(strjoin({'','prj',obj.Names.project},filesep));
            obj.Paths.doc = fullfile(obj.Paths.project,'doc');
            obj.Paths.matlab = fullfile(obj.Paths.doc,'matlab');
            obj.Paths.runData = char(strjoin(obj.Paths.psfLocFolders(1:11),filesep));
        end
        function getNetlist(obj)
            % getNetlist Loads the corner's netlist
            %  Extracts the cell view name and test bench cell name from
            %  the netlist
            %
            % See also: adexl.corner
            obj.Paths.Netlist = strsplit(obj.Paths.psf,filesep);
            obj.Paths.Netlist = fullfile(char(strjoin(obj.Paths.netlist(1:end-1),filesep)),'netlist', 'input.scs');
            obj.Netlist = loadTextFile(obj.Paths.netlist);
            obj.Names.cellView = obj.Netlist{5}(22:end);
            obj.Names.testBenchCell = obj.Netlist{4}(22:end);
        end
        function getSpectreLog(obj)
        % Get Spectre log file
            obj.Paths.spectreLog = fullfile(obj.Paths.psf,'spectre.out');
            obj.Info.log = loadTextFile(obj.Paths.spectreLog);
        end
        function ProcessCorner = getProcessCorner(obj)
        % Get the model information
            obj.Paths.modelFileInfo = strsplit(obj.Paths.psf,filesep);
            obj.Paths.modelFileInfo = fullfile(char(strjoin(obj.Paths.modelFileInfo(1:end-1),filesep)),'netlist', '.modelFiles');
            obj.Info.modelFileInfo = loadTextFile(obj.Paths.modelFileInfo);
            if(~isempty(obj.Info.modelFileInfo) && (length(obj.Info.modelFileInfo)==1))
                obj.ProcessCorner = obj.Info.modelFileInfo{1}(strfind(obj.Info.modelFileInfo{1},'section=')+8:end);
            elseif(~isempty(obj.Info.modelFileInfo))
                obj.ProcessCorner = 'NOM';
            else
                obj.ProcessCorner = '';
            end
            ProcessCorner = obj.ProcessCorner;
        end
        function getDataDCop(obj)
            obj.Analyses.dcOp.info = evalc(sprintf('cds_srr(obj.Paths.psf,''dcOp-dc'')'));
        end
        function getDataTransient(obj)
            obj.Analyses.transient.info = cds_srr(obj.Paths.psf,'tran-tran');
            % Save transient waveforms
            
            if(isfield(obj.Analyses.transient,'waveformsList') && ...
               ~isempty(obj.Analyses.transient.waveformsList))
                for wfmNum = 1:length(obj.Analyses.transient.waveformsList)
                    obj.Analyses.transient.(obj.Analyses.transient.waveformsList{wfmNum}) = cds_srr(obj.Paths.psf,'tran-tran',obj.Analyses.transient.waveformsList{wfmNum});
                end
            end
        end
        function set.test(obj,val)
        % 
            if(~isa(val,'adexl.test'))
                error('VirtuosoToolbox:adexl_corner:set_test','test needs to be a adexl.corner object')
            end
%             if(~strcmp(obj.Names.test,val.name))
%                 error('VirtuosoToolbox:adexl_corner:set_test','test does not match the test of this corner')
%             end
            obj.test = val;
        end
        function set.Process(obj,val)
            if(ischar(val))
                val = processes.(val);
            end
            if(~isa(val,'cdsProcess'))
                error('VirtuosoToolbox:adexl_corner:setProcess','Process must be subclassed from cdsProcess')
            end
            obj.Process = val;
        end
        function fieldName = analysisName(obj,analysis)
        % Gives the actual field name in the analysis property when an
        % analysis name is given
        %
        % USAGE
        %  fieldName = obj.analysisName(analysis)
        %
        % See also: adexl.corner
            switch analysis
                case {'dc','dc-dc'}
                    fieldName = 'dc';
                case 'stb-stb'
                    fieldName = 'stb';
                case {'dcOp','dcOp-dc'}
                    fieldName = 'dcOp';
                otherwise
                    error('VirtuosoToolbox:adexl_corner:analysisName',...
                          'Analysis not defined');
            end
        end
    end
    methods (Static)
        function simNum = getSimNum(axlCurrentResultsPath)
        % getSimNum Provides the sin number for each corner.  This is 
        %  useful for saving each corner to a seperate adexl.result object
        %  and then returning to adexl by using the Results variable to show
        %  the correspondence between the adexl corner names and the sim
        %  number
        %
        % INPUTS
        %  axlCurrentResultsPath - Path to the psf folder containing the
        %   simulation results for a given corner.  This variable is
        %   provided in the workspace by adexl.
        % OUTPUTS
        %  SimNum - Simulation number assigned that is assigned to each
        %   corner.
        % EXAMPLE
        %  Results = adexl.corner.getSimNum(axlCurrentResultsPath);
        %  MAT(Results) = adexl.corner.getSimNum(axlCurrentResultsPath);
        %  MAT.save(filePath)
        %
        % see also:
            psfLocFolders = strsplit(axlCurrentResultsPath,filesep);
            simNum = str2double(psfLocFolders{12});
        end
        function loadSTC()
        %loadSTC Loads a set of corners from a 
        end
    end
end

