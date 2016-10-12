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
            p.addParameter('signals',[],@iscell);
            p.addParameter('transientSignals',[],@iscell);
            p.addParameter('dcSignals',[],@iscell);
            p.addParameter('desktop',false,@islogical);
            p.parse(axlCurrentResultsPath,varargin{:});
            if(~isempty(p.Results.transientSignals))
                obj.analyses.transient.waveformsList = p.Results.transientSignals;
            elseif(~isempty(p.Results.signals))
                obj.analyses.transient.waveformsList = p.Results.signals;
            end
            if(~isempty(p.Results.dcSignals))
                obj.analyses.dc.waveformsList = p.Results.dcSignals;
            elseif(~isempty(p.Results.signals))
                obj.analyses.dc.waveformsList = p.Results.signals;
            end
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
            if(any(strcmp('dc-dc',obj.info.availableAnalyses)))
                obj.getDataDC;
            end
            
            if(any(strcmp('tran-tran',obj.info.availableAnalyses)))
                obj.getDataTransient;
            end
            if(any(strcmp('dcOp-dc',obj.info.availableAnalyses)))
                obj.getDataDCop;
            end
            
            obj.paths.psfPathCorners = strjoin([psfLocFolders(1:11) 'psf' psfLocFolders(13) 'psf'],filesep);
            obj.paths.run = strjoin(psfLocFolders(1:11),filesep);
            obj.paths.psfTmp = strjoin([psfLocFolders(1:10) ['.tmpADEDir_' obj.names.user] obj.names.test [obj.names.library '_' obj.names.testBenchCell '_schematic_spectre'] 'psf'],filesep);
            obj.paths.runObjFile = strjoin({obj.paths.psfTmp 'runObjFile'},filesep);
            obj.info.runObjFile = cdsOutMatlab.loadTextFile(obj.paths.runObjFile);
            numCornerLineNum = strncmp('"Corner_num"',obj.info.runObjFile,12);
            obj.info.numCorners = str2double(obj.info.runObjFile{numCornerLineNum}(13:end));
            corners = {obj.info.runObjFile{find(numCornerLineNum)+1:find(numCornerLineNum)+obj.info.numCorners}};
            obj.info.cornerNames = cellfun(@(x,y) x(y(3)+1:end-1),corners,strfind(corners,'"'),'UniformOutput',false);
            obj.names.corner = obj.info.cornerNames{obj.simNum};
            obj.getCornerName;
            obj.filepath = [];
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
            obj.analyses.dc.info = cds_srr(obj.paths.psf,'dc-dc');
            % Save transient waveforms
            if(~isempty(obj.analyses.dc.waveformsList))
                for wfmNum = 1:length(obj.analyses.dc.waveformsList)
                    obj.analyses.transient.(obj.analyses.dc.waveformsList{wfmNum}) = cds_srr(obj.paths.psf,'tran-tran',obj.analyses.transient.waveformsList{wfmNum});
                end
            end
        end
        function getDataDCop(obj)
            obj.analyses.dcOp.info = cds_srr(obj.paths.psf,'dcOp-dc');
        end
        function getDataTransient(obj)
            obj.analyses.transient.info = cds_srr(obj.paths.psf,'tran-tran');
            % Save transient waveforms
            if(~isempty(obj.analyses.dc.waveformsList))
                for wfmNum = 1:length(obj.analyses.transient.waveformsList)
                    obj.analyses.transient.(obj.analyses.transient.waveformsList{wfmNum}) = cds_srr(obj.paths.psf,'tran-tran',obj.analyses.transient.waveformsList{wfmNum});
                end
            end
        end
        function getCornerName(obj)
        % Gets the name of the corner.  This name is set in the Cadence
        % corner setup
%         	obj.info.cornerRunFile = cdsOutMatlab.loadTextFile(fullfile(obj.paths.psfPathCorners,'runObjFile'));
            obj.info.cornerRunFileDir = dir(obj.paths.psfPathCorners);
%             obj.info.corners.numCorners = strfind(obj.info.cornerRunFile,'"Corner_num"');
        end
        function data = save(obj,varargin)
        % Save Saves the cdsOutMatlab dataset to a file
        %   The dataset is saved to a file which contains a table named 
        %   data containing the data in a column and the library name, test
        %   bench cell name (TBcell), test name, and result name.
        % 
        %  Each dataset should only contain a single result
        %
        % USAGE
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
                [obj.filepath] = deal(p.Results.filePath);
                filePath = p.Results.filePath;
            elseif(~isempty({obj.filePath}))
                filePath = char(unique({obj.filepath}));
            else
                filePath = [];
            end
                        
            if(isempty(filePath))
                [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'; ...
                	'*.*',  'All Files (*.*)'},'Select file to save data');
                if isequal(filename,0) || isequal(pathname,0)
                    disp('User pressed cancel')
                    return;
                else
                    [obj.filepath] = deal(fullfile(pathname,filename));
                end
            end
            % Append to an existing file
%             obj(1).filepath
            
            % Save
            % MAT.Project.testBenchCell.Test = obj
            library = unique(arrayfun(@(x) x.names.library,obj,'UniformOutput',false));
            TBcell = unique(arrayfun(@(x) x.names.testBenchCell,obj,'UniformOutput',false));
            test = unique(arrayfun(@(x) x.names.test,obj,'UniformOutput',false));
            result = unique(arrayfun(@(x) x.names.result,obj,'UniformOutput',false));
            result = regexprep(result,'\(|\)|\.| ','_');
            data = table(obj,library,TBcell,test,result);
            data.Properties.VariableNames = {'data','library','TBcell','test','result'};
%             MAT.(char(library)).(char(TBcell)).(char(test)).(char(result)) = obj;
            save(obj(1).filepath,'data');
%             save(obj(1).filepath,'MAT');
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
        function dir(obj,dirPath)
            if(length(obj)>1)
            	error('VirtuosoToolbox:cdsOutMatlab','Only run on a single corner of cdsOutMatlab, not all of them.');
            end
            if(~ischar(dirPath))
                error('VirtuosoToolbox:cdsOutMatlab','The input must be a char path location or dir type');
            end
            pathList = fields(obj.paths);
            pathNameIdx = strcmp(dirPath,pathList);
            if(any(pathNameIdx))
                dirName = pathList{pathNameIdx};
                dirPath = obj.paths.(dirName);
                pathDirs = strsplit(dirPath,{'/','\'});
            else
                pathDirs = strsplit(dirPath,{'/','\'});
                dirName = pathDirs{end};
            end
            if(ispc && strcmp(pathDirs{1},''))
                dirPath = ['R:' dirPath];
            end
                [obj.info.dir.(dirName)] = deal(dir(dirPath));
        end
    end
    methods (Static)
        function simNum = getSimNum(axlCurrentResultsPath)
        % getSimNum Provides the sin number for each corner.  This is 
        %  useful for saving each corner to a seperate cdsOutMatlab object
        %  and then returning to adexl by using the Results variable to show
        %  the correspondence between the adexl corner names and the sim
        %  number
        %
        % INPUTS
        %  axlCurrentResultsPath - Path to the psf folder containing the
        %   simulation results for a given corner.  This variable is
        %   provided in the workspace by adexl.
        % OUTPUTS
        %  simNum - Simulation number assigned that is assigned to each
        %   corner.
        % EXAMPLE
        %  Results = cdsOutMatlab.getSimNum(axlCurrentResultsPath);
        %  MAT(Results) = cdsOutMatlab.getSimNum(axlCurrentResultsPath);
        %  MAT.save(filePath)
        %
        % see also:
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
                data = data.data;
            elseif(iscell(filePath))
                data = table;
                for fileIdx = 1:length(filePath)
                    dataIn = load(filePath{fileIdx});
                    data = [data;dataIn.data];
                end
            else
                data = table;
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

