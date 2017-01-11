classdef variables < dynamicprops
    %variables A set of ADEXL Variables
    %   Defines a set of variables for a corner, a test, or an adexl
    %   cellview. (global variables)  Each variable is defined as a
    %   property of the class.  The variable is renamed and a warning
    %   issued if a variable name is not a valid MATLAB identifier.
    %   
    % USAGE
    %  varObj = adexl.variables('VariableName',VariableValue,...)
    %  varObj = adexl.variables({'VariableName1','VariableName2',...},...
    %                           {VariableValue1,  VariableValue2,...})
    %  TO DO: (not implemented)                            
    %  varObj = adexl.variables(resultsDir,'VariableName',VariableValue,...)
    % EXAMPLE
    %  variables = adexl.variables('VDD',3:0.5:5.0, 'VIO',[1.65 1.8 1.95]);
    %  
    % METHODS
    %  add - defines a new variable
    %  import - Imports corners data from an adexl output directory
    %  remove - deletes a variable from the variable set (object)
    %  variableNames - Returns a cell array of the variable names
    %  variableValues - Returns a cell array of the variable values
    
    properties (Hidden)
        metaVariables meta.DynamicProperty
    end
    
    methods
        function obj = variables(varargin)
        % Creates a new varible set object
        %
        % See Also: adexl.variables
            if(nargin>1 && mod(length(varargin),2)~=0)
                error('skyVer:adexl_variables:Constructor',...
                 'Even number of inputs.  User must supply variable-value and parameter-value pairs.');
            end
            if((nargin == 2) && iscell(varargin{1}))
                obj.add(varargin{1},varargin{2});
            elseif(nargin>1)
            % Add the specified variables
%             cellfun(@(x,y) obj.add(x,y),varargin(1:2:end),varargin(2:2:end));
                obj.add(varargin(1:2:end),varargin(2:2:end));
            end
        end
        function add(obj,varargin)
        % add Adds the specified variable(s) to the variable set.
        %  The name input specifies the name(s) of the variable(s) as a
        %  char or cell string.  The value input specifies the value of 
        %  the variable(s).  If the value input must also be a cell array
        %  if the names input is a cell array.  If a adexl.variables object
        %  is supplied the variables are copied from that object to the
        %  current object.
        %
        % USAGE
        %  obj.add(name,value)
        %  obj.add(adexlVariablesObj)
        %
        % See Also: adexl.variables
            if(nargin == 2)
                if(~isa(varargin{1},'adexl.variables'))
                    error('skyVer:adexl_variables:BadSingleInput',...
                          'A single input must be another adexl.variables object');
                end
                obj.add(properties(varargin{1}),varargin{1}.values);
            elseif(nargin == 3)
                name = varargin{1};
                value = varargin{2};
                if(isempty(name))
                    error('skyVer:adexl_variables:add',...
                          'Variable name must be specified');
                end
                if(iscell(name))
                    if(length(name) == 1)
                        obj.add(char(name),value)
                    else
                        cellfun(@(x,y) obj.add(x,y),name,value);
                    end
                elseif(ischar(name))
                    varName = matlab.lang.makeValidName(name,...
                               'ReplacementStyle','underscore',...
                               'Prefix','var_');
                    if(~strcmp(name,varName))
                        warning('skyVer:adexl_variables:add',...
                        ['Variable name "' name '" is not a valid matlab identifier and will be replaced with "' varName '"']);
                    end
                    obj.metaVariables(end+1) = obj.addprop(name);
                    if(iscell(value))
                        obj.(name) = value{1};
                    else
                        obj.(name) = value;
                    end
                else
                    error('skyVer:adexl_variables:add',...
                          'Variable name must be a char or cell string');
                end
            else
                error('skyVer:adexl_variables:numInputs',...
                          'Wrong number of inputs');
            end
        end
        function remove(obj,name)
        %remove Deletes a given variable
        %
        % USAGE
        % obj.remove(name);
        %  Removes the variable with the given name
        % INPUTS
        %  name - The name of the variable to delete (char)
        %
        % See Also: adexl.variables
            metaProp = obj.findprop(name);
            delete(metaProp);
        end
        function import(obj,source)
        % import Imports corners data from an adexl output directory
        %  TODO: Add support for .csv and .SDB corners files
        %  TODO: Add support for importing from adexl state (XML) files
        % USE:
        %  obj.import(CornerResultDir);
        %   Imports corner variables from the specified corner result
        %   directory
        % See Also: adexl.variables
        
            % Import from a corner result directory
            if(ischar(source))
                [~,varNames] = evalc(sprintf('cds_srr(%s,''variables'')',source));
                varNames = varNames.variable;
                varValues = cell(length(varNames),1);
                for i = 1:length(varNames)
                    [~,varValues{i}] = ...
                    evalc(sprintf('cds_srr(%s,''variables'',varNames{i})',source));

        %             [~,obj.Info.variablesData.(regexprep(varNames{i}(1:end-6),'\(|\)|\.| ',''))] = ...
        %             evalc(sprintf('cds_srr(obj.paths.psf,''variables'',varNames{i})'));
                end
                obj.add(varNames,varValues);
            end
        end
        function out = numVars(obj)
        % numVars Returns the number of variables in a scalar variables
        %  object
        % See Also: adexl.variables
            out = length(properties(obj));
        end
        function out = names(obj)
        %variableNames Returns a cell array containing the names of the
        % variables that make up the variable set (variables object)
        % See Also: adexl.variables
        out = properties(obj);
        end
        function out = isVariable(obj,variableName)
        %isVariable Returns true if the variable name is a variable in the
        % object, false otherwise
            out = any(strcmp(obj.names,variableName));
        end
        function out = values(obj)
        %variableValues Returns a cell array containing the values of the
        % variables that make up the variable set (variables object) in a
        % cell array
        % See Also: adexl.variables
            out = cellfun(@(x) obj.(x),properties(obj),'UniformOutput',false);
        end
        function docNode = export(obj)
        % export Exports the variables to an XML document.  This
        % document can then be used to copy the root node to another
        % document using the importNode or adoptNode methods.
        %
        % Document Object Map (DOM) Creation Help:
        %  http://docs.oracle.com/javase/6/docs/api/org/w3c/dom/package-summary.html
        %
        % USAGE
        %  xmlDocument = 
        %
        % EXAMPLE DOM NODE OUTPUT
        %	<vars>
        %       <var>temperature
        %           <value>-40 25 140</value>
        %       </var>
        %       <var>VBAT
        %           <value>2.5 3.8 5</value>
        %       </var>
        %	</vars>
        %
        % See Also: adexl.variables, xmlwrite
            docNode = com.mathworks.xml.XMLUtils.createDocument('vars');
            docRootNode = docNode.getDocumentElement;
            names = obj.variableNames;
            for varNum = 1:obj.numVars
                varElement = docNode.createElement('var');
                varElement.appendChild(docNode.createTextNode(names{varNum}));
                    valueElement = docNode.createElement('value');
                    if(ischar(obj.(names{varNum})))
                        valueElement.appendChild(docNode.createTextNode(obj.(names{varNum})));
                    elseif(isnumeric(obj.(names{varNum})))
                        valueElement.appendChild(docNode.createTextNode(sprintf('%g ',obj.(names{varNum}))));
                    end
                    varElement.appendChild(valueElement);
                docRootNode.appendChild(varElement);
            end
        end
        function ocn = ocean(obj,type,varargin)
        %ocean The ocean XL commands for generating the variables set
        %
        % USAGE
        %  varsObj.ocean('global')
        %   Returns the ocean xl commands for a global variable
        %  varsObj.ocean('test')
        %   Returns the ocean xl commands for a test variable
        %  varsObj.ocean('corner', MipiStates) or varsObj.ocean('corners')
        %   Returns the ocean xl commands for a corners set variable.  The
        %   MipiStates (skyMipiStates) object for the view must also be provided.
        % OUTPUTS
        %  ocnCell - Column cell array containing one line of the set of commands
        %   in each index
        % See Also: adexl.variables
            switch type 
                case 'global'
                    vars = setdiff(obj.names,{'SET_DATA_WORD','SET_PROCESS'}); % Need to rework to handle SET_DATA_WORD
                    ocn = cellfun(@(x) ['ocnxlSweepVar(   "' x '" ' num2str(obj.(x)) ' )'],vars,'UniformOutput',false);
                case 'test'
                    vars = setdiff(obj.names,'SET_DATA_WORD'); % Need to rework
                    ocn = cellfun(@(x) ['desVar(   "' x '" ' num2str(obj.(x)) ' )'],vars,'UniformOutput',false);
                case {'corner','corners'}
                    vars = setdiff(obj.names,{'SET_PROCESS'}); % Need to rework to handle SET_DATA_WORD
                    if(obj.isVariable('SET_DATA_WORD'))
                        obj.SET_DATA_WORD = strsplit(obj.SET_DATA_WORD(2:end),',$');
                        obj.SET_DATA_WORD = cellfun(@(word) varargin{1}.State(word), obj.SET_DATA_WORD,'UniformOutput',false);
                        obj.SET_DATA_WORD = vect2colon([obj.SET_DATA_WORD{:}],'Delimiter','off');
%                         obj.SET_DATA_WORD = strjoin(obj.SET_DATA_WORD,',');
                    end
                    ocn = cellfun(@(x) ['("variable" "' x '" ' num2str(obj.(x)) ' )'],vars,'UniformOutput',false);
            end
        end
    end
    
end

