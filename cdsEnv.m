classdef cdsEnv
    %cdsEnv Cadence environment setup
    %   stores the Cadence environment and standard project setup for use 
    %   in all projects
    
    properties
        prjDirBase % Folder for storing all projects
        ocnBinDir % Directory containing the ocean binary
        userName
        smbDrv % Samba drive to the unix file system
    end
    
    methods
        function obj = cdsEnv(varargin)
        % cdsEnv Loads a 'cdsEnv.mat' file containing information on
        % the users Cadence environment setup.
        %  Usage: env = cdsEnv loads the file from userpath
        %         env = cdsEnv(envFile) loads it from envFile
        %         env = cdsEnv('prompt') prompts the user to select
        %                  the file
            
            % Load the environment mat file
            if(nargin == 0)
                currPath = userpath;
                envInfoFile = fullfile(currPath(1:end-1), 'cdsEnv.mat');
                if(exist(envInfoFile,'file'))
                    env = load(envInfoFile);
                else
                    env = cdsEnv('prompt');
                end
            elseif(nargin == 1)
                if(exist(varargin{1},'file'))
                    env = load (varargin{1});
                elseif(strcmpi(varargin{1},'prompt'))
                    [FileName,PathName,~] = uigetfile('.mat','Select a cdsEnv.mat file');
                    if(FileName == 0)
                        error('cdsEnv:noEnvInfo',...
                             'Need to set the Cadence environment information and save it to cdsEnv.mat located in userpath');
                    else
                        env = load(fullfile(PathName, FileName));
                        
                    end
                else
                    error('cdsEnv:noEnvInfo',...
                     'Need to set the Cadence environment information and save it to cdsEnv.mat located in userpath');
                end
            else
                error('cdsEnv:tooManyInputArgs','Too many input arguements');
            end
            obj.prjDirBase = env.env.prjDirBase;
            obj.ocnBinDir = env.env.ocnBinDir;
            obj.userName = env.env.userName;
            obj.smbDrv = env.env.smbDrv;
        end
        function obj=set.prjDirBase(obj,val)
			if(~ischar(val))
				error('userName:notStr','prjDirBase must be a string')
			end
			obj.prjDirBase = val;
		end
        function obj=set.ocnBinDir(obj,val)
			if(~ischar(val))
				error('userName:notStr','ocnBinDir must be a string')
			end
			obj.ocnBinDir = val;
		end
        function obj=set.userName(obj,val)
			if(~ischar(val))
				error('userName:notStr','userName must be a string')
			end
			obj.userName = val;
        end
        function obj=set.smbDrv(obj,val)
			if(~isunix)
                if(~ischar(val))
                    error('userName:notStr','smbDrv must be a string')
                end
                obj.smbDrv = val;
            end
        end
    end
    methods (Static)
        function save(varargin)
            % Saves an environment configuration to the matlab userpath.
            % Usage:
            %  cdsEnv.save(env)
            %   Saves an existing instance of cdsEnv
            %  cdsEnv.save(prjDirBase,ocnBinDir,userName,smbDrv);
            %   saves an environment variable with the given properties
            %  
            if(nargin == 1)
                env = varargin{1};
            elseif(nargin == 3)
                env.prjDirBase = varargin{1};
                env.ocnBinDir = varargin{2};
                env.userName = varargin{3};
                env.smbDrv = [];
            elseif(nargin == 4)
                env.prjDirBase = varargin{1};
                env.ocnBinDir = varargin{2};
                env.userName = varargin{3};
                env.smbDrv = varargin{4};
            end
            currPath = userpath;
            file = fullfile(currPath(1:end-1), 'cdsEnv.mat');
            save(file, 'env')
        end
    end
end

