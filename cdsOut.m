classdef cdsOut < matlab.mixin.SetGet
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        info
        
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
            p.addOptional('data',[],@(x) true);
            p.addParameter('desktop',false,@islogical);
            p.parse(varargin{:});
            
            % start desktop (optional)
            if(p.Results.desktop)
                obj.startDesktop
            end
        end
        function dir(obj,dirPath)
        % dir Saves the contents of dirPath to obj.info.dir.(dirPath)
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
                [obj.info.dir.(dirName)] = deal(dir(dirPath));
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
        function getPaths(obj)
            obj.paths.project = char(strjoin({'','prj',obj.names.project},filesep));
            obj.paths.doc = fullfile(obj.paths.project,'doc');
            obj.paths.matlab = fullfile(obj.paths.doc,'matlab');
            obj.paths.runData = char(strjoin(obj.paths.psfLocFolders(1:11),filesep));
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
    end
    methods (Static)
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
        function startDesktop
        % Starts the matlab desktop if it isn't already in use
            if(~desktop('-inuse'))
                desktop % displays the desktop but can take a long time to open
                %workspace % View variables as they change
                %commandwindow
            end
        end
        function logLoc = startLog(varargin)
        % Starts a log (diary) of the matlab output including warnings and
        % errors.  Returns the location of the log.
        %
        % USAGE
        %  logPath = startLog(obj,axlCurrentResultsPath)
            if(nargin == 1)
                psfLocFolders = strsplit(varargin{1},filesep);
                logLoc = char(strjoin({'','prj',psfLocFolders{5},'doc','matlab'},filesep));
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
    end
end

