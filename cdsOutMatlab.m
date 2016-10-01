classdef cdsOutMatlab < hgsetget
    %cdsOutMatlab Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        simNum
        analyses
        names
        paths
        temp
        processCorner
        variables % sim variable values
        info
        netlist
    end
    properties (Access = private,Constant,Hidden)
        analysisTypes = {'tran-tran','stb-stb','stb-margin.stb','dcOp-dc'};
    end
    properties (Transient = true)
        filepath
    end
    methods
        function obj = cdsOutMatlab(axlCurrentResultsPath,varargin)
        %cdsOutMatlab Creates a new matlab output saving script
            
            if(~isunix)
                error('VirtuosoToolbox:cdsOutMatlab',...
                      'This class is for use in a script that is ran as an output in ADEXL or in a unix MATLAB session');
            end
            psfLocFolders = strsplit(axlCurrentResultsPath,filesep);
            
            % Basic Information and log
            obj.names.project = psfLocFolders{5};
            obj.paths.project = char(strjoin({'','prj',obj.names.project},filesep));
            obj.paths.doc = fullfile(obj.paths.project,'doc');
            obj.paths.matlab = fullfile(obj.paths.doc,'matlab');
            if(~isdir(obj.paths.matlab))
                [log_success,log_msg,log_msgid] = mkdir(obj.paths.matlab);
                if(~log_success)
                    error(log_msgid,log_msg);
                end
            end
            diary(fullfile(obj.paths.matlab,'matlab.log')); % Enable MATLAB log file
            obj.simNum = str2double(psfLocFolders{12});
            obj.paths.psf = char(axlCurrentResultsPath);
            obj.names.result = psfLocFolders{11};
            obj.names.user = psfLocFolders{4};
            
            obj.names.library = psfLocFolders{6};
            obj.names.testBenchCell = psfLocFolders{7};
            obj.names.test = psfLocFolders{13};
            
            % Parse Inputs
            p = inputParser;
            %p.KeepUnmatched = true;
            p.addRequired('axlCurrentResultsPath',@ischar);
            p.addParameter('transientSignals',[],@iscell);
            p.addParameter('desktop',false,@islogical);
            p.parse(axlCurrentResultsPath,varargin{:});
            obj.analyses.transient.waveformsList = p.Results.transientSignals;
            
            % start desktop (optional)
            if(p.Results.desktop && ~desktop('-INUSE'))
                desktop % displays the desktop but can take a long time to open
                %workspace % View variables as they change
                %commandwindow
            end
            % Get netlist
            obj.paths.netlist = strsplit(obj.paths.psf,filesep);
            obj.paths.netlist = fullfile(char(strjoin(obj.paths.netlist(1:end-1),filesep)),'netlist', 'input.scs');
            obj.netlist = cdsOutMatlab.loadTextFile(obj.paths.netlist);
            % Get Spectre log file
            obj.paths.spectreLog = fullfile(obj.paths.psf,'spectre.out');
            obj.info.log = cdsOutMatlab.loadTextFile(obj.paths.spectreLog);
            % Get the model information
            obj.paths.modelFileInfo = strsplit(obj.paths.psf,filesep);
            obj.paths.modelFileInfo = fullfile(char(strjoin(obj.paths.modelFileInfo(1:end-1),filesep)),'netlist', '.modelFiles');
            obj.info.modelFileInfo = cdsOutMatlab.loadTextFile(obj.paths.modelFileInfo);
            if(~isempty(obj.info.modelFileInfo) && (length(obj.info.modelFileInfo)==1))
                obj.processCorner = obj.info.modelFileInfo{1}(strfind(obj.info.modelFileInfo{1},'section=')+8:end);
            elseif(~isempty(obj.info.modelFileInfo))
                obj.processCorner = 'NOM';
            else
                obj.processCorner = '';
            end
            
            % Load Analyses
            obj.info.datasets = cds_srr(obj.paths.psf);
            obj.info.availableAnalyses = intersect(obj.info.datasets,obj.analysisTypes);
            obj.getVariables;
            obj.temp = obj.variables.temp;
            if(any(strcmp('stb-stb',obj.info.availableAnalyses)))
                obj.getDataSTB;
            end
            if(any(strcmp('dcOp-dc',obj.info.availableAnalyses)))
                obj.getDataDC;
            end
            if(any(strcmp('tran-tran',obj.info.availableAnalyses)))
                obj.getDataTransient;
            end
                

            obj.paths.psfPathCorners = strjoin([psfLocFolders(1:11) 'psf' psfLocFolders(13) 'psf'],filesep);
            obj.getCornerName;
%             obj.info.corners.runObjFile = cdsOutMatlab.loadTextFile(fullfile(obj.paths.psfPathCorners,'runObjFile'));
        end
        function getAllProperties(obj)
        % psf properties
            obj.info.tranDatasets = cds_srr(obj.paths.psf,'tran-tran');
            properties = obj.info.tranDatasets.prop;
            for i = 1:length(properties)
                obj.info.properties.(regexprep(properties{i},'\(|\)|\.| ','')) = ...
                cds_srr(obj.paths.psf,obj.info.availableAnalyses{1},properties{i});
            end
        end
        function getAllPropertiesCorners(obj)
        % Corners psf properties
            obj.info.corners.tranDatasets = cds_srr(obj.paths.psfPathCorners,'tran-tran');
            cornerProperties = obj.info.corners.tranDatasets.prop;
            for i = 1:length(cornerProperties)
                obj.info.corners.properties.(regexprep(cornerProperties{i},'\(|\)|\.| ','')) = ...
                cds_srr(obj.paths.psfPathCorners,'tran-tran',cornerProperties{i});
            end
        end
        function getVariables(obj)
        % Gets the corner's variable data
        %
        % USE:
        %  obj.getVariables;
            obj.info.variables = cds_srr(obj.paths.psf,'variables');
            varNames = cds_srr(obj.paths.psf,'variables');
            varNames = varNames.variable;
            for i = 1:length(varNames)
                obj.info.variablesData.(regexprep(varNames{i}(1:end-6),'\(|\)|\.| ','')) = ...
                cds_srr(obj.paths.psf,'variables',varNames{i});
            end
            obj.variables = obj.info.variablesData;
        end
        function getDataSTB(obj)
        % Loads stability (stb) analysis data
            obj.analyses.stb.phaseMargin = cds_srr(obj.paths.psf,'stb-margin.stb','phaseMargin');
            obj.analyses.stb.gainMargin = cds_srr(obj.paths.psf,'stb-margin.stb','gainMargin');
            obj.analyses.stb.loopGain = cds_srr(obj.paths.psf,'stb-stb','loopGain');
            obj.analyses.stb.phaseMarginFrequency = cds_srr(obj.paths.psf,'stb-margin.stb','phaseMarginFreq');
            obj.analyses.stb.gainMarginFrequency = cds_srr(obj.paths.psf,'stb-margin.stb','gainMarginFreq');
            obj.analyses.stb.probe = cds_srr(obj.paths.psf,'stb-stb','probe');
            obj.analyses.stb.info = cds_srr(obj.paths.psf,'stb-stb');
            obj.analyses.stb.infoMargin = cds_srr(obj.paths.psf,'stb-margin.stb');
        end
        function getDataDC(obj)
            obj.analyses.dc.info = cds_srr(obj.paths.psf,'dcOp-dc');
        end
        function getDataTransient(obj)
            obj.analyses.transient.info = cds_srr(obj.paths.psf,'tran-tran');
            % Save transient waveforms
            for wfmNum = 1:length(obj.analyses.transient.waveformsList)
                obj.analyses.transient.(obj.analyses.transient.waveformsList{wfmNum}) = cds_srr(obj.paths.psf,'tran-tran',obj.analyses.transient.waveformsList{wfmNum});
            end
        end
        function getCornerName(obj)
        % Gets the name of the corner.  This name is set in the Cadence
        % corner setup
%         	obj.info.cornerRunFile = cdsOutMatlab.loadTextFile(fullfile(obj.paths.psfPathCorners,'runObjFile'));
            obj.info.cornerRunFileDir = dir(obj.paths.psfPathCorners);
%             obj.info.corners.numCorners = strfind(obj.info.cornerRunFile,'"Corner_num"');
        end
        function save(obj,varargin)
        % Save data
            p = inputParser;
            p.addOptional('filepath',[],@ischar);
            p.parse(varargin{:});
            obj.filepath = p.Results.filepath;
            % Save
            save(p.Results.filepath,'obj')
            
        end
        function signalOut = loadSignal(obj,analysis,signal)
            analysis = lower(analysis);
            switch analysis
                case {'transient','tran-tran','tran','trans'}
                    cdsAnalysisName = 'tran-tran';
                    analysis = 'transient';
                otherwise
                    warning('Wrong or unsupported analysis type');
            end
        	signalOut = cds_srr( obj.paths.psf, cdsAnalysisName, signal);
            obj.data.(analysis).(signal) = signalOut;
        end
    end
    methods (Static)
        function simNum = getSimNum(axlCurrentResultsPath)
            psfLocFolders = strsplit(axlCurrentResultsPath,filesep);
            simNum = str2double(psfLocFolders{12});
        end
        function out = loadTextFile(path)
        % loadTextFile Loads a text file located at the given path.
        %  Returns a cell array with each line of the file a row in the
        %  cell array.
        %
        %  textFileCell = loadTextFile(path)
        %
            [fid,errorMessage] = fopen(path,'r');
            if(fid >0)
                out = textscan(fid,'%s','Delimiter',sprintf('\n'));
                out = out{1};
                fclose(fid);
            else
                disp(errorMessage);
                disp(['Could not open ' path  sprintf('\n') errorMessage]);
                
                out = '';
            end
        end
    end
    
end

