classdef cdsCorners < hgsetget
    % cdsCorners PVT Corners
    %   A class for describing and generating a set of corners and writing 
    %   a corners file.
    
    properties
        fileName
        processLoc
        process = []
        names = {}
        temps = []
        vNames = {}  % Variable Names
        vValues = [] % Variable Values
        pNames = {}  % Parameter Names
        pValues = [] % Parameter Values
        modelFiles = {}
        modelGroups = {}
        description = ''
        testNames = {};
        testEnables = {};
        cornersTable
    end
    properties (Dependent,GetAccess=private)
        tempStr % 
    end
    methods
        function obj = cdsCorners(varargin)
        % Creates a set of PVT corners that can be written to a corners
        %  file or ocean script for use in a Cadence Virtuoso simulation
        %
        % USAGE
        %  c = cdsCorners;
        %  c = cdsCorners(names)
        %  c = cdsCorners(names, temps)
        %
        % INPUTS
        %  names - the names of each corner in a cell array of strings
        %  temps - Sets the temperatures.  Must be a cell array of
        %          temperature vectors.
        %
        % EXAMPLES
        %  c = cdsCorners
        %   Creates an empty set of corners
        %
        %  names = {'m30c','27c','90c'};
        %  temps = {[-30 27 90]};
        %  c = cdsCorners(names, temps)
        %   Creates a set of corners with the given temperature values
        %  see also: cdsPrj
            p = inputParser;
            p.addOptional('names',{[]}, @iscell);
            p.addOptional('temps',{[]});
            p.parse(varargin{:});
            obj.names = p.Results.names;
            obj.temps = p.Results.temps;
        end
        function addVariable(obj,name,values)
        % addVariable Adds a variable to the corners list
        %  Stores the variable's values as strings.
            p = inputParser;
            p.addRequired('name', @(x) iscell(x) || ischar(x));
            p.parse(name);
            obj.vNames{end+1} = p.Results.name;
            obj.vValues{end+1} = values;
            if(~ischar(values{1}))
                warning('value format error. Variable value needs to be a string.');
            end
        end
%         function temps = addTemp(varargin)
% %             pNames =  
%         end
%         function processes = addProcess(varargin)
%         end
%         function voltages = addSupply(varargin)
%         end
        function write(obj,file,varargin)
        % WRITE Exports the corners to a file.
        %
        % hCorners.write(file,...)
        %
        % INPUTS
        %  file - full file path to save the corners file.
        %
        % Parameters
        %  format - The output format to save the corners information. 
        %           Default: CSV
        %           CSV: write to a CSV file.
        %           SDB, XML: Write to an XML file.
        %           If the file input has one of these two extensions, the
        %           proper format will be selected.
            p = inputParser;
            p.addRequired('file', @(x) iscell(x) || ischar(x));
            p.addParameter('format','CSV',...
                           @(x) any(validatestring(x,{'CSV','SDB','XML'})));
            p.addParameter('roomTemp',false, @islogical);
            p.parse(file,varargin{:});
            
            format = p.Results.format;
            [pathstr,name,ext] = fileparts(file);
            
            if(strcmpi(format,'XML'))
                format = 'SDB';
            elseif(isempty(varargin) && any(strcmpi(ext,{'SDB','XML'})))
                format = 'SDB';
            end
            file = fullfile(pathstr,[name '.' lower(format)]);
            
            if(strcmp(format,'CSV'))
                obj.writeCSV(file);
            else
                obj.writeSDB(file)
            end
        end
        function writeCSV(obj,file)
        % writeCSV Writes the corners setup to a csv file.
        %  USAGE:
        %   h.writeCSV(file)
            fid = fopen(file,'w+');
            % Corner Names
            fprintf(fid,'%s\r\n',strjoin([{'Corner'} obj.testNames(:)'],','));
            % Corner Enables
            enables = cell(1,length(obj.testNames));
            [enables{:}] = deal('t');
            fprintf(fid,'%s\r\n',strjoin([{'Enable'} enables(:)'],','));
            % Temperatures
%             temp_out = cellfun(@(x) cellstr(x)', ...
%                        cellfun(@num2str,obj.temps,'UniformOutput',false),'UniformOutput',false); % Convert to a cell string
%             temp_out = cellfun(@(y) strjoin(y,','),...
%                        cellfun(@strtrim,temp_out,'UniformOutput',false),'UniformOutput',false); % Form each entry
%             temp_out = cellfun(@(x) ['"' x '"'],temp_out,'UniformOutput',false);
            temp_out = obj.tempStr;
            fprintf(fid,'%s\r\n',strjoin([{'Temperature'} temp_out(:)'],','));
            % Variables
            for var =1:length(obj.vNames)
                value = cellfun(@(x) ['"' x '"'],obj.vValues{var},'UniformOutput',false);
                fprintf(fid,'%s\r\n',strjoin([obj.vNames(var) value(:)'],','));
            end
            % Test Enables
            testEn = cell(1,length(obj.testNames));
            for ten = 1:length(obj.testNames)
                testEn(obj.testEnables{ten}) = deal({'t'});
                testEn(~obj.testEnables{ten}) = deal({'f'});
                fprintf(fid,'%s\r\n',strjoin([['t Test::' obj.testNames{ten}] testEn(:)'],','));
            end
            fclose(fid);
        end
        function docRootNode = writeSDB(obj,file,varargin)
        % Write the corners to a .sdb (XML) file that can be loaded in
        % Cadence.
        %
        % USAGE
        %  rootNode = h.writeSDB(file)
        %
        % INPUTS
        %  file SDB file path
        % OUTPUTS
        %  rootNode root DOM node
        %
        % see also: write writeCSV
        
        % Parse Inputs
        p = inputParser;
        p.addRequired(file,@ischar);
        p.addParameter('roomTemp',false, @islogical);
        p.parse(file,varargin{:});
        
        % Document Object Map Creation
        % http://docs.oracle.com/javase/6/docs/api/org/w3c/dom/package-summary.html
            docNode = com.mathworks.xml.XMLUtils.createDocument('setupdb');
            docRootNode = docNode.getDocumentElement;
            docRootNode.setAttribute('version','5');

            activeElement = docNode.createElement('active');
            activeElement.appendChild(docNode.createTextNode('Active Setup'));
                % TESTS
                tests = docNode.createElement('tests');
                    testElementBase = docNode.createElement('test');
                    testElementBase.setAttribute('enabled','1');
                        tool = docNode.createElement('tool');
                        tool.appendChild(docNode.createTextNode('ADE'));
                        testElementBase.appendChild(tool);
                    for i =1:length(obj.testNames)
                        testElement = testElementBase.cloneNode(true);
                        testElement.insertBefore(docNode.createTextNode(sprintf('%s',obj.testNames{i})),testElement.getLastChild);
                        tests.appendChild(testElement);
                    end
                activeElement.appendChild(tests);
                disabledTests = docNode.createElement('disabledtests');
                activeElement.appendChild(disabledTests);
                corners = docNode.createElement('corners');
                    for c = 1:length(obj.names)
                        corner = docNode.createElement('corner');
                        corner.setAttribute('enabled','1');
                        corner.appendChild(docNode.createTextNode(obj.names{c}));
                        vars = docNode.createElement('vars');
                        % Temperature
                        temp = docNode.createElement('var');
                        temp.appendChild(docNode.createTextNode('temperature'));
                        value = docNode.createElement('value');
                        if(~p.Results.roomTemp)
                            value.appendChild(docNode.createTextNode(obj.tempStr{c}(2:end-1)));
                        else
                            value.appendChild(docNode.createTextNode('25'));
                        end
                        temp.appendChild(value);
                        % Variables
                        vars.appendChild(temp);
                            for v=1:length(obj.vNames)
                                var = docNode.createElement('var');
                                var.appendChild(docNode.createTextNode(obj.vNames{v}));
                                    value = docNode.createElement('value');
                                    value.appendChild(docNode.createTextNode(obj.vValues{v}{c}));
                                var.appendChild(value);
                                vars.appendChild(var);
                            end
                        corner.appendChild(vars);
                        corners.appendChild(corner);
                    end
                activeElement.appendChild(corners);
            docRootNode.appendChild(activeElement);
            % HISTORY
            history = docNode.createElement('history');
            history.appendChild(docNode.createTextNode('History'));
            docRootNode.appendChild(history);
            xmlwrite(file,docNode);
        end
        function temp_out = get.tempStr(obj)
            temp_out = cellfun(@(x) cellstr(x)', ...
                       cellfun(@num2str,obj.temps,'UniformOutput',false),'UniformOutput',false); % Convert to a cell string
            temp_out = cellfun(@(y) strjoin(y,','),...
                       cellfun(@strtrim,temp_out,'UniformOutput',false),'UniformOutput',false); % Form each entry
            temp_out = cellfun(@(x) ['"' x '"'],temp_out,'UniformOutput',false);
        end
        function importVariables(obj,variablesTable)
            
        end
    end
    methods(Static)
        function checkFilePath
        end
    end
end

