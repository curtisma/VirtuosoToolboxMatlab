classdef spec
    %spec Output Specification
    %   Specification for an output
    % SYNTAX
    %  output.spec = spec(output,Type,Value,...)
    % PROPERTIES & INPUTS
    %  Output - The output to be specified
    %  Type - The specification type
    %   Options: 'Range','<','min','>','max'
    %  Value - The value of the specification.  This should be a vector of
    %  length 2 for a "Range" type spec or a single numerical scalar otherwise.
    % PARAMETERS & INPUTS
    %  Typical - The typical value for the spec.  (numeric scalar)
    %  Corner - Enables the specified corner.  The specified corner's spec 
    %   is overwritten.
    %  Weight - A weighing factor for the spec (Used for optimization)
    
    properties
        Test
        Output
        Type
        Value
        Typical
        Corner
        Weight
    end
    
    methods
        function obj = spec(varargin)
            p = inputParser;
            p.addOptional('Output',adexl.output.empty,@(x) isa(x,'adexl.output'));
            p.addOptional('Type','',@(x) any(validatestring(x,{'','>','max','<','min','range'})));
            p.addOptional('Value',[],@(x) isnumeric(x) & (length(x) < 3));
            p.addParameter('Typical',[],@(x) isnumeric(x) & (length(x) <= 1));
            p.addParameter('Corner',adexl.cornerSet.empty,@(x) isa(x,'adexl.cornerSet'));
            p.addParameter('Weight',[],@(x) isnumeric(x) & (length(x) == 1) & (x <=1) & (x>=0));
            p.parse(varargin{:});
%             obj.Test = p.Results.Test;
            obj.Output = p.Results.Output;
            obj.Type = p.Results.Type;
            obj.Value = p.Results.Value;
            obj.Typical = p.Results.Typical;
            obj.Corner = p.Results.Corner;
            obj.Weight = p.Results.Weight;
        end
        function skl = skill(obj)
        %skill Creates a skill command to create the spec
        %   Returns a char array of skill commands for creating the spec
        %
        % USAGE
        %  skl = h.skill(testName);
        %   where h is an output handle or array of handles and skl is a
        %   char.
        %   
        % See Also: adexl.output
            switch obj.Type
                case 'range'
                    sklSpec = [' ?range ' num2str(obj.Value(1)) ':' num2str(obj.Value(2)) ' '];
                case '<'
                    sklSpec = [' ?lt ' num2str(obj.Value) ' '];
                case 'min'
                    sklSpec = [' ?min ' num2str(obj.Value) ' '];
                case '>'
                    sklSpec = [' ?gt ' num2str(obj.Value) ' '];
                case 'max'
                    sklSpec = [' ?max ' num2str(obj.Value) ' '];
            end
            if(~isempty(obj.Corner))
                sklCorner = [' ?corner "' obj.Corner.Name '"'];
            else
                sklCorner = '';
            end
%             skl = ['axlAddSpecToOutput(sdb "' obj.Corner.Test.Name '" "' obj.Output.Name '" ' sklSpec sklCorner ')'];
            skl = sprintf('axlAddSpecToOutput(sdb "%s" "%s" %s%s)',obj.Corner.Test.Name,obj.Output.Name,sklSpec,sklCorner);
%             skl = sprintf('axlAddSpecToOutput(sdb "%s" "%s")\naxlAddSpecToOutput(sdb "%s" "%s" %s%s)',obj.Corner.Test.Name,obj.Output.Name,obj.Corner.Test.Name,obj.Output.Name,sklSpec,sklCorner);
        end
    end
    
end

