classdef cdsSkill
    %cdsSkill A set of Cadence skill utilities
    %   A set of static functions for converting from MATLAB to Skill
    
    properties
    end
    
    methods (Static)
        function out = sklLogical(logicIn)
        %sklLogical Returns a skill representation of a logical data type.
        % returns a char according to the following:
        %   true: t
        %   false: nil
        % See Also: adexl.output
            if(~islogical(logicIn))
                error('skyVer:adexl_output:sklLogical','The input must be logical');
            end
            if(logicIn)
                out = 't';
            else
                out = 'nil';
            end
        end
        function out = cell2list(in)
        %cell2list Converts a cell to a cadence list char array.
        % returns a char with a Cadence list literal
        %  e.g. '(in{1} in{2}) for a cell input, in, of length 2
        % See Also: cdsAdexl
            out = sprintf('''(%s)',strjoin(in,' '));
        end
        function out = cellStr2list(in)
        %cell2list Converts a cell to a cadence list char array.
        % returns a char with a Cadence list literal
        %  e.g. '("in{1}" "in{2}") for a cell input, in, of length 2
        % See Also: cdsAdexl
            out = sprintf('''("%s")',strjoin(in,'" "'));
        end
    end
    
end

