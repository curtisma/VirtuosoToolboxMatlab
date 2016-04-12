classdef cdsPrj < hgsetget
    %cdsPrj A Cadence Project
    %   A project for simulation and post-processing of data from the Cadence
    %   Virtuoso IC design environment.
    %
    %  Author: Curtis Mayberry
    %   Curtisma3@gmail.com
    %   Curtisma.org
    %
    % cdsPrj is the project manager that saves all the data and scripts for
    %  a project.  An existing project can be loaded or  a new one started
    %  by creating a new cdsPrj project as shown in the examples below.
    %
    % Examples
    %  prj = cdsPrj('projectName')
    %   starts a new project or loads an existing project with the same
    %   name.
    %  cdsPrj.saveEnv('projectDirectory','
    %
    %  TODO: Finish grep_prj
    %  TODO: Add XML project information save feature
    %
    % See also cdsEnv
    properties
        projectName % name of the current project
        maskName % mask number
        prjDir % Directory where all the project files are stored
		%TOdate % Tape-out date
        %components % Components
    end
    
    properties (GetAccess=private)
        env
        prjMatFile
        descriptionText
    end
    properties(Dependent)
        matlabDir % Project's matlab working directory
        docPath % Project documentation folder
        prjPath % Project directory path
        prjFile % Project .mat file
        description % Description of the project
    end
    
    methods
        function obj = cdsPrj(varargin)
            % constructs a new project
            % Usage:
            %  prj = cdsprj;
            %   Creates an empty project that 
            %  prj = cdsprj(prjDir);
            %   Opens an existing project or creates a new one if one
            %   doesn't exist yet.
            %  prj = cdsprj(prjDir,'new');
            %   Overwrites any existing project
            %  prj = cdsPrj(prjDir,projectName,maskName);
            
            % Load environment variables
            obj.env = cdsEnv;
            % parse inputs
            if(nargin >= 1)
                obj.prjDir = varargin{1};
            end
            if(~isempty(obj.prjDir))
                obj= cdsPrj.load(varargin{1});
            end
            if(nargin == 3)
                % Setup project information
                obj.projectName = varargin(2);
                obj.maskName = varargin(3);
            end
            %Setup directory structure
            if((~isempty(obj.prjDir)) && (~exist(obj.matlabDir,'dir')))
                    mkdir(obj.matlabDir);
            end
            if((~isempty(obj.prjDir)) && (~exist(obj.docPath,'dir')))
                mkdir(obj.prjDir, 'doc');
            end
        end
        function prjPath = get.prjPath(obj)
            if(ispc)
                prjPath = fullfile(obj.env.smbDrv,obj.env.prjDirBase,obj.prjDir);
            else
                prjPath = fullfile(obj.env.prjDirBase,obj.prjDir);
            end
            if(~exist(prjPath,'dir'))
                error('prjPath:doesNotExist','prjPath doesnt exist');
            end
        end
        function docPath = get.docPath(obj)
                docPath = fullfile(obj.prjPath,'doc');
        end
        function prjDir = get.prjDir(obj)
        	prjDir = obj.prjDir;
        end
        function prjFile = get.prjFile(obj)
            %
            if(isempty(obj.prjMatFile))
                prjFile = fullfile(obj.matlabDir,strcat(obj.prjDir,'.mat'));
            else
                prjFile = obj.prjMatFile;
            end
        end
        function matlabDir = get.matlabDir(obj)
                matlabDir = fullfile(obj.docPath,'matlab');
        end
        function description = get.description(obj)
            description = ['Project: ' obj.projectName ...
                           '\nmaskName: ' obj.maskName ...
                           '\nDescription: ' obj.descriptionText];
        end
        function obj = set.prjFile(obj,val)
            if(isempty(val))
                obj.prjMatFile = [];
            else
                [~,name,ext] = fileparts(val);
                if(strcmp(ext,'.mat'))
                    obj.prjMatFile = val;
                elseif(strcmp(name,obj.projectName))
                    obj.prjMatFile = [];
                else
                    obj.prjMatFile = [];
                    warning('Project .mat file set to default name');
                end
            end
        end
		function obj = set.projectName(obj,val)
			assert(ischar(val),'projectName:notStr','projectName must be a string');
			obj.projectName = val;
		end
		function obj = set.maskName(obj,val)
			assert(ischar(val),'maskName:notStr','maskName must be a string');
			obj. maskName = val;
        end
		function obj = set.prjDir(obj,val)
			assert(ischar(val),'prjDir:notStr','prjDir must be a string');
			obj.prjDir = val;
        end
        function obj = set.description(obj,val)
            assert(ischar(val),'description:notStr','description must be a string');
            obj.descriptionText = val;
        end
		function save(obj)
        % saves the project to a .mat file
            save(obj.prjFile,'obj')
        end
	end

	methods (Static)
        function obj = load(prj)
        % load Loads an existing project
        %  
        % Usage:
        %  load('')
        %  load('')
            if(ischar(prj))
                [~,~,ext] = fileparts(prj);
            end
            if(isa(prj,'cdsPrj'))
                prj = fullfile(prj.matlabDir,prj);
            elseif(ischar(prj))
                prj_temp = cdsPrj;
                prj_temp.prjDir = prj;
                prj = prj_temp.prjFile;
            else
                warning('cdsPrj:load:badInput','bad load input');
            end
			obj = load(prj, 'obj');
            obj = obj.obj;
        end
		function saveEnv(prjDirBase, ocnBinDir, userName)
			cdsEnv.save(prjDirBase, ocnBinDir, userName);
        end
        
    end
end

