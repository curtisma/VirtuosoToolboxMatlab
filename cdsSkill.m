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
    end
    
end

