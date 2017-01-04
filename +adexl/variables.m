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
    %  
    
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
        function add(obj,name,value)
        % add Adds the specified variable(s) to the variable set.
        %  The name input specifies the name(s) of the variable(s) as a
        %  char or cell string.  The value input specifies the value of 
        %  the variable(s).  The value input can also be 
        %
        % USAGE
        %  obj.add(name,value)
        %
        % See Also: adexl.variables
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
                obj.(name) = value;
            else
                error('skyVer:adexl_variables:add',...
                      'Variable name must be a char or cell string');
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
        function out = variableNames(obj)
        %variableNames Returns a cell array containing the names of the
        % variables that make up the variable set (variables object)
        out = properties(obj);
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
    end
    
end

