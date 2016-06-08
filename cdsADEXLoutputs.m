classdef cdsADEXLoutputs < hgsetget
    %cdsADEXLoutputs A class for generating a set of outputs to be imported
    %into ADEXL.
    %   Detailed explanation goes here
    
    properties
        outputs
    end
    
    methods
        function obj = cdsADEXLoutputs(varargin)
            if(nargin>0)
                obj.add(varargin{:});
            else
                obj.outputs = table;
            end
        end
        function add(obj,varargin)
        % addOutput Adds outputs to the ADEXL output set
        % 
        % INPUTS
        %  There are 3 methods to input ADEXL outputs
        %
        %  TABLE (basic)
        %   A table whose input variables match those of the ADEXL table
        %   COLUMNS:
        %    Test - Output type (string)
        %    Name - Output name (string)
        %    Details - 
        %    Type - Output type (string)  options: signal (net) or expr
        %    EvalType - Evaluation type (string,optional) 
        %     options: point or corners
        %    Plot - enable plotting (boolean,optional)
        %    Save - enable data save (boolean,optional)
        %    Spec - 
        %    Weight - 
        %    Units - 
        %  TABLE (multiple measurements per output)
        %   A table format where each row is a signal or net name and each
        %   column specifies a measurement to be made on that signal
        %
        %
            if((nargin == 2) && (istable(varargin{1})))
            % A Table has been input
                if(cdsADEXLoutputs.isTableMultiple(varargin{1}))
                    obj.addTableMultiple(varargin{1})
                elseif(cdsADEXLoutputs.isTableSingle(varargin{1}))
                    obj.addTableSingle(varargin{1})
                else
                    error('VirtuosoToolbox:cdsADEXLoutputs', 'Unsupported input format');
                end
            elseif(nargin == 3  && all(cellfun(@isstr,varargin)))
                addOutputs = table(varargin{2},varargin{3});
                addOutputs.Properties.VariableNames = {'Test','Details'};
                addOutputs.Propertis.RowNames = varargin{1};
            end
        end
        function addTableSingle(obj,in)
        % addTableSingle Adds a table containing a subset of the ADEXL
        % outputs
            addOutputs = in;
            if(any(ismember(in.Properties.VariableNames,'Name')))
                addOutputs.Properties.RowNames = in.Name;
                addOutputs.Name = [];
            elseif(isempty(in.Properties.RowNames))
                error('VirtuosoToolbox:cdsADEXLoutputs',...
                'Need to specify the measurement name in a variable or as the RowNames property of the table');
            end
            if(~isempty(in.Properties.UserData))
                props = fields(in.Properties.UserData);
                if(ismember(props,'Type'))
                    in.Properties.UserData.Type = strrep(in.Properties.UserData.Type,'signal','net');
                end
                for propN = 1:length(fields(in.Properties.UserData))
                   if(ischar(in.Properties.UserData.(props{propN})))
                    val = cell(1,height(addOutputs));
                    [val{:}] = deal(in.Properties.UserData.Type);
                    addOutputs.val = val';
                    addOutputs.Properties.VariableNames{end} = props{propN};
                   end
                end
            end
            if(isempty(obj.outputs))
                obj.outputs = addOutputs;
            else
                obj.outputs = [obj.outputs; addOutputs];
            end
        end
        function addTableMultiple(obj,in)
        % addTableMultiple Adds a table containing multiple measurements to
        % be made on a set of signals
            UserDataOptions = {'Test','Type', 'EvalType', 'Plot', 'Save','Spec','weight','Units','Digits','Notation','Suffix'};
            % Check measurement properties
            if(~isempty(in.Properties.UserData) && ...
              ((isstruct(in.Properties.UserData) && ~all(ismember(fields(in.Properties.UserData),UserDataOptions))) || ...
              (istable(in.Properties.UserData) && ~all(ismember(in.Properties.UserData.Properties.RowNames,UserDataOptions)))))
                error('VirtuosoToolbox:cdsADEXLoutputs',...
                'Improper measurement property format.  Revise the measurement properties in the Properties.UserData of the input table.');
            end
            props = fields(in.Properties.UserData);
            % Set Default Type property to expression
            if(~ismember(props,'Type'))
                in.Properties.UserData.Type = 'expr'; 
                props = fields(in.Properties.UserData);
            end
            propsCell = props(structfun(@iscell,in.Properties.UserData));
            propValCell = cell((width(in)+1)*height(in),length(propsCell));
            % Process each measurement
            for col = 1:width(in)
                i_start = (col-1)*height(in)+1;
                i_end = col*height(in);
                % Setup measurement properties which are cells
                if(~isempty(in.Properties.UserData) && isstruct(in.Properties.UserData))
                    for propN = 1:length(propsCell)
                        [propValCell{i_start:i_end,propN}] = deal(in.Properties.UserData.(propsCell{propN}){col});
                    end
                end
                Name(i_start:i_end) = strcat(in.Properties.RowNames,'_',in.Properties.VariableNames(col));
                Details(i_start:i_end) = in{:,col};
            end
            % Add single value (character) Properties
            if(~isempty(in.Properties.UserData) && isstruct(in.Properties.UserData))
                propsChar = props(structfun(@ischar,in.Properties.UserData));
                if(~isempty(propsChar))
                    if(ismember(propsChar,'Type'))
                        strrep(in.Properties.UserData.Type,'signal','net');
                    end
                    propValChar = cell((width(in)+1)*height(in),length(propsChar));
                    for propN = 1:length(propsChar)
                        [propValChar{:,propN}] = deal(in.Properties.UserData.(propsChar{propN}));
                    end
                end
            end
            % Add signals
            i_start = width(in)*height(in)+1;
            i_end = (width(in)+1)*height(in);
            Name(i_start:i_end) = in.Properties.RowNames;
            signal = @(out) ['/' out];
            Details(i_start:i_end) = cellfun(signal,in.Properties.RowNames,'UniformOutput',false);
            [propValCell{i_start:i_end,:}] = deal('');
            % Add to table
            Details = Details';
            addOutputs = cell2table([Details propValChar propValCell]);
            addOutputs.Properties.RowNames = Name;
            addOutputs.Properties.VariableNames = ['Details' propsChar' propsCell];
            addOutputs.Properties.DimensionNames = {'Name', 'Measurement'};
            if(isempty(obj.outputs))
                obj.outputs = addOutputs;
            else
                % Add variables that already exist in the outputs table
                missingVarNames = setdiff(obj.outputs.Properties.VariableNames,addOutputs.Properties.VariableNames);
                if(~isempty(missingVarNames))
                    missingVars = cell(height(addOutputs),length(missingVarNames));
                    [missingVars{:,:}] = deal('');
                    addOutputs = [addOutputs cell2table(missingVars)];
                    addOutputs.Properties.VariableNames((end-length(missingVarNames)+1):end) = missingVarNames;
                end
                % Add new variables to the outputs table
                missingVarNames = setdiff(addOutputs.Properties.VariableNames,obj.outputs.Properties.VariableNames);
                if(~isempty(missingVarNames))
                    missingVars = cell(height(obj.outputs),length(missingVarNames));
                    [missingVars{:,:}] = deal('');
                    obj.outputs = [obj.outputs cell2table(missingVars)];
                    obj.outputs.Properties.VariableNames((end-length(missingVarNames)+1):end) = missingVarNames;
                end
                obj.outputs = [obj.outputs; addOutputs];
            end
            
            
        end
        function write(obj,varargin)
        % write Writes the outputs to a csv file
        % 
        % USAGE
        %  outputs.write(file);
        %
        % INPUTS
        %  file - complete file path with a .csv extension
        %
        % see also: cdsADEXLoutputs cdsADEXLoutputs.add
            
            % Parse Inputs
            p = inputParser;
            p.addRequired('file',@isstr);
            p.parse(varargin{:});
            
            [fid, message] = fopen(varargin{1},'w');
            if(~isempty(message))
                error('VirtuosoToolbox:cdsADEXLoutputs',message);
            end
            Name = obj.outputs.Properties.RowNames;
%             Test = obj.outputs.Test;
%             Details = obj.outputs.Details;
            fprintf(fid,['Name,' strjoin(obj.outputs.Properties.VariableNames,',') '\n']);
            format = cell(1,width(obj.outputs)+1);
            [format{:}] = deal('%s,');
            format{end} = '%s\n'; % Replace trailing comma with a new line character
            values = table2cell(obj.outputs);
            for lineN = 1:length(Name)
                fprintf(fid,strjoin(format),Name{lineN},values{lineN,:});
            end
            fclose(fid);
        end
        function disp(obj)
        % disp A custom display method
            disp@hgsetget(obj);
            disp('    outputs:');
            disp(obj.outputs);
        end
    end
    methods (Static)
        function out = isTableMultiple(in)
            out = ~any(ismember(in.Properties.VariableNames,'Details'));
        end
        function out = isTableSingle(in)
            out = any(ismember(in.Properties.VariableNames,'Details'));
        end
    end
end

