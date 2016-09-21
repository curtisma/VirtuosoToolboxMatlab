classdef cdsOutMatlab < hgsetget
    %cdsOutMatlab Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        simNum
        analyses
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
        
%         desktop
            if(~isunix)
                error('VirtuosoToolbox:cdsOutMatlab',...
                      'This class is for use in a script that is ran as an output in ADEXL');
            end
            psfLocFolders = strsplit(axlCurrentResultsPath,filesep);
            
            % Basic Information
            obj.info.names.project = psfLocFolders{5};
            obj.info.projectPath = char(strjoin({'','prj',obj.info.names.project},filesep));
            matlabFolder = fullfile(obj.info.projectPath,'doc','matlab');
            if(~isdir(matlabFolder))
                [log_success,log_msg,log_msgid] = mkdir(matlabFolder);
                if(~log_success)
                    error(log_msgid,log_msg);
                end
            end
            diary(fullfile(matlabFolder,'matlab.log')); % Enable MATLAB log file
            obj.simNum = str2double(psfLocFolders{12});
            obj.info.psfPath = char(axlCurrentResultsPath);
            obj.info.names.result = psfLocFolders{11};
            obj.info.names.user = psfLocFolders{4};
            
            obj.info.names.library = psfLocFolders{6};
            obj.info.names.testBenchCell = psfLocFolders{7};
            obj.info.names.test = psfLocFolders{13};
            
            % Get netlist
            obj.info.netlistPath = strsplit(obj.info.psfPath,filesep);
            obj.info.netlistPath = fullfile(char(strjoin(obj.info.netlistPath(1:end-1),filesep)),'netlist', 'input.scs');
            obj.netlist = cdsOutMatlab.loadTextFile(obj.info.netlistPath);
            % Get Spectre log file
            obj.info.logPath = fullfile(obj.info.psfPath,'spectre.out');
            obj.info.log = cdsOutMatlab.loadTextFile(obj.info.logPath);
            % Get the model information
            obj.info.modelFileInfoPath = strsplit(obj.info.psfPath,filesep);
            obj.info.modelFileInfoPath = fullfile(char(strjoin(obj.info.modelFileInfoPath(1:end-1),filesep)),'netlist', '.modelFiles');
            obj.info.modelFileInfo = cdsOutMatlab.loadTextFile(obj.info.modelFileInfoPath);
            if(~isempty(obj.info.modelFileInfo) && (length(obj.info.modelFileInfo)==1))
                obj.processCorner = obj.info.modelFileInfo{1}(strfind(obj.info.modelFileInfo{1},'section=')+8:end);
            elseif(~isempty(obj.info.modelFileInfo))
                obj.processCorner = 'NOM';
            else
                obj.processCorner = '';
            end
            % Load Analyses
            obj.info.datasets = cds_srr(obj.info.psfPath);
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
                
%             workspace % View variables as they change
%             commandwindow
%             desktop % displays the desktop but can take a long time to
%             open
            obj.info.corners.psfPath = strjoin([psfLocFolders(1:11) 'psf' psfLocFolders(13) 'psf'],filesep);
%             obj.info.corners.runObjFile = cdsOutMatlab.loadTextFile(fullfile(obj.info.corners.psfPath,'runObjFile'));
        end
        function getAllProperties(obj)
        % psf properties
            obj.info.tranDatasets = cds_srr(obj.info.psfPath,'tran-tran');
            properties = obj.info.tranDatasets.prop;
            for i = 1:length(properties)
                obj.info.properties.(regexprep(properties{i},'\(|\)|\.| ','')) = ...
                cds_srr(obj.info.psfPath,obj.info.availableAnalyses{1},properties{i});
            end
        end
        function getAllPropertiesCorners(obj)
        % Corners psf properties
            obj.info.corners.tranDatasets = cds_srr(obj.info.corners.psfPath,'tran-tran');
            cornerProperties = obj.info.corners.tranDatasets.prop;
            for i = 1:length(cornerProperties)
                obj.info.corners.properties.(regexprep(cornerProperties{i},'\(|\)|\.| ','')) = ...
                cds_srr(obj.info.corners.psfPath,'tran-tran',cornerProperties{i});
            end
        end
        function getVariables(obj)
        % Gets the corner's variable data
        %
        % USE:
        %  obj.getVariables;
            obj.info.variables = cds_srr(obj.info.psfPath,'variables');
            varNames = cds_srr(obj.info.psfPath,'variables');
            varNames = varNames.variable;
            for i = 1:length(varNames)
                obj.info.variablesData.(regexprep(varNames{i}(1:end-6),'\(|\)|\.| ','')) = ...
                cds_srr(obj.info.psfPath,'variables',varNames{i});
            end
            obj.variables = obj.info.variablesData;
        end
        function getDataSTB(obj)
        % Loads stability (stb) analysis data
            obj.analyses.stb.phaseMargin = cds_srr(obj.info.psfPath,'stb-margin.stb','phaseMargin');
            obj.analyses.stb.gainMargin = cds_srr(obj.info.psfPath,'stb-margin.stb','gainMargin');
            obj.analyses.stb.loopGain = cds_srr(obj.info.psfPath,'stb-stb','loopGain');
            obj.analyses.stb.phaseMarginFrequency = cds_srr(obj.info.psfPath,'stb-margin.stb','phaseMarginFreq');
            obj.analyses.stb.gainMarginFrequency = cds_srr(obj.info.psfPath,'stb-margin.stb','gainMarginFreq');
            obj.analyses.stb.probe = cds_srr(obj.info.psfPath,'stb-stb','probe');
            obj.analyses.stb.info = cds_srr(obj.info.psfPath,'stb-stb');
            obj.analyses.stb.infoMargin = cds_srr(obj.info.psfPath,'stb-margin.stb');
        end
        function getDataDC(obj)
            obj.analyses.dc.info = cds_srr(obj.info.psfPath,'dcOp-dc');
        end
        function getDataTransient(obj)
            obj.analyses.transient.info = cds_srr(obj.info.psfPath,'tran-tran');
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
        	signalOut = cds_srr( obj.info.psfPath, cdsAnalysisName, signal);
            obj.data.(analysis).(signal) = signalOut;
        end
        function sendEmail(obj)
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
            fid = fopen(path,'r');
            if(fid >0)
                out = textscan(fid,'%s','Delimiter',sprintf('\n'));
                out = out{1};
                fclose(fid);
            else
                warning(['Could not open ' path]);
                out = '';
            end
        end
        function data = collectData(MATin)
            
        end
    end
    
end

