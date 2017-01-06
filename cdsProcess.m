classdef cdsProcess < matlab.mixin.SetGet
    %cdsProcess Describes an IC process
    %   An abstract class for defining a process
    
    properties (Constant, Abstract)
%         cornerLoc    % location of the corners directory
        Description    % Description of the process
        Variables  % Process Specific Variables
        ModelPath      % Path to the simulation models
%         vars_version % Release number for the variables.
    end
    
    methods
    end
    
end

