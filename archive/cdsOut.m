classdef cdsOut < matlab.mixin.SetGet
    %cdsOut An abstract class for Cadence Matlab output data handling
    %   A class for handling corners information
    %
    % USAGE
    %  obj = obj@cdsOut(varargin{:}); % Superclass constructor
    %  obj = cdsOutSubClass([data],...)
    % INPUTS
    %  data (optional) - A path to the dataset or a object of cdsOut
    %   subclass
    % PARAMETERS
    %  desktop - opens a matlab desktop if its not already open.  It does
    %   take a long time to open.
    % PROPERTIES
    %  Name - name of the cdsOut object
    %  Info - Extra information [struct]
    %  names - List of different names [struct]
    %  paths - Folder paths [struct]
    %
    % METHODS
    %  dir  - Saves directory contents to obj.Info.dir.(dirPath)
    %  find - Utility for finding sim results
    %  addCorner - Common addCorner code - to be used at the start of a
    %   subclass's addCorner function which overrides it
    %  startLog - Starts a matlab diary log in doc/matlab folder
    %  getPaths - Loads path information from input data path
    % STATIC METHODS
    %  getSimNum - Extracts the sim number from the data path
    %  loadTextFile - loads a text file to a cell array with each row in
    %   the array a line of the text file
    %  startDesktop - starts a MATLAB desktop gui
    %  isResultFolder - Determines if a path is a full result dataset (true) 
    %   or a corner dataset (false)
    %
    % See also: cdsOutRun,cdsOutTest,cdsOutCorner
    properties
        Name
        Info
        DUT
    end
    properties (Abstract)
        names
        paths
    end
    
    methods
        function obj = cdsOut(varargin)
            % Parse Inputs
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('data',[],@(x) ischar(x) || isa(x,'cdsOut'));
            p.addParameter('desktop',false,@islogical);
%             p.addParameter('DUT',cdscell.empty,@(x) isa(x,'cdsCell'));
            p.parse(varargin{:});
            
            % start desktop (optional)
            if(p.Results.desktop)
                obj.startDesktop
            end
        end
        function dir(obj,dirPath)
        % dir Saves the contents of dirPath to obj.Info.dir.(dirPath)
        % 
        % USAGE
        %  obj.dir(dirPath)
        %
        % Saves it as a cell array of char arrays
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
                [obj.Info.dir.(dirName)] = deal(dir(dirPath));
        end
        function out = find(varargin)
        % Utility for finding sim results
            if(nargin > 1)
                if(ispc)
                    if(isempty(obj.names.user))
                        user =getenv('USERNAME');

                    end
                    library = ['R:/prj/sim_data_s/' user filesep varargin{1}];
                    if(~isdir(library))
                        
                    end
                else
                    error('VirtuosoToolbox:cdsOut:unix','find is not supported in unix');
                end
            end
            if(nargin == 2)
            else
                out = '';
            end
        end
        function corner = addCorner(obj,corner,varargin)
            if(ischar(corner))
            % Initialize corner
                if(nargin == 2)
                    corner = cdsOutCorner(corner);
                elseif(nargin>2)
                    corner = cdsOutCorner(corner,varargin{:});
                else
                    error('VirtuosoToolbox:cdsOutMatlab:addCorner','Not enough inputs')
                end
            end
            if(~isa(corner,'cdsOutCorner'))
                error('VirtuosoToolbox:cdsOutTest:addCorner','corner must be a cdsOutCorner');
            end
        end
        function logLoc = startLog(obj,varargin)
        % startLog Starts a log (diary) of the matlab output including 
        % warnings and errors.  Returns the location of the log.
        %
        % USAGE
        %  logPath = startLog(obj,resultDir)
        %
        % See also: cdsOut
            if(nargin == 2)
                psfLocFolders = strsplit(varargin{1},filesep);
                logLoc = char(strjoin({'','prj',psfLocFolders{5},'doc','matlab'},filesep));
            else
                error('skyVer:cdsOut:wrongInputs','Wrong number of inputs');
            end
            if(~isempty(logLoc))
                if(~isdir(logLoc))
                    [log_success,log_msg,log_msgid] = mkdir(logLoc);
                    if(~log_success)
                        error(log_msgid,log_msg);
                    end
                end
            else
                logLoc = userpath;
                if(ispc)
                    logLoc = logLoc(1:end-1);
                end
            end
            diary(fullfile(logLoc,'matlab.log')); % Enable MATLAB log file
        end
        function getPaths(obj)
            obj.paths.project = char(strjoin({'','prj',obj.names.project},filesep));
            obj.paths.doc = fullfile(obj.paths.project,'doc');
            obj.paths.matlab = fullfile(obj.paths.doc,'matlab');
            obj.paths.runData = char(strjoin(obj.paths.psfLocFolders(1:11),filesep));
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
            try
                psfLocFolders = strsplit(char(axlCurrentResultsPath),filesep);
                simNum = str2double(psfLocFolders{12});
            catch ME
                simNum = -1;
                disp(ME)
            end
        end
        function out = loadTextFile(path)
        % loadTextFile Loads a text file located at the given path.
        %  Returns a cell array with each line of the file a row in the
        %  cell array.
        %
        % USAGE
        %  textFileCell = loadTextFile(path)
        %
        % See also: cdsOut
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
        function startDesktop
        % startDesktop Starts the matlab desktop if it isn't already in use
        %
        % USAGE
        %  cdsOut.startDesktop
        %
        % See also: cdsOut
            if(~desktop('-inuse'))
                desktop % displays the desktop but can take a long time to open
                %workspace % View variables as they change
                %commandwindow
            end
        end
        function out = isResultFolder(resultPath)
        %isResultFolder Output is true if the provided result path is a 
        % results folder containing multiple corners.  If a path to a 
        % corner psf folder is provided this function returns false.
        %
        % USAGE
        %  out = isResultFolder(resultPath)
        %
        % See also: cdsOut
            psfLocFolders = strsplit(resultPath,filesep);
            out = ~((strcmp('results',psfLocFolders{9}) && length(psfLocFolders) == 14) || ...
                    (strcmp('results',psfLocFolders{8}) && length(psfLocFolders) == 13));
        end
        function logLoc = startLogStatic(varargin)
        % startLog Starts a log (diary) of the matlab output including 
        % warnings and errors.  Returns the location of the log.
        %
        % USAGE
        %  logPath = startLogStatic(resultDir)
        %
        % See also: cdsOut
            if(nargin == 1)
                psfLocFolders = strsplit(varargin{1},filesep);
                logLoc = char(strjoin({'','prj',psfLocFolders{5},'doc','matlab'},filesep));
            else
                error('skyVer:cdsOut:wrongInputs','Wrong number of inputs');
            end
            if(~isempty(logLoc))
                if(~isdir(logLoc))
                    [log_success,log_msg,log_msgid] = mkdir(logLoc);
                    if(~log_success)
                        error(log_msgid,log_msg);
                    end
                end
            else
                logLoc = userpath;
            end
            diary(fullfile(logLoc,'matlab.log')); % Enable MATLAB log file
        end
        function libName = resultLib(result)
        % resultLib Returns the library of the provided result.  The result
        %  is a char path that points to either a corner result (e.g. from 
        %  the axlCurrentResultsPath variable provided in a Cadence script)
        %  or a path to a result folder.
        %
        % USAGE
        %  libName = cdsOut.resultLib(result)
        %
        % See also: cdsOut
            psfLocFolders = strsplit(result,filesep);
            libName = psfLocFolders{5};
        end
    end
end

