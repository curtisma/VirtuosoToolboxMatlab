classdef cdsProcess < matlab.mixin.SetGet
    %cdsProcess Describes an IC process
    %   An abstract class for defining a process
    properties
        NomModelFileSections
    end
    properties (SetAccess = protected)
        Variables adexl.variables % Process Specific Variables including 
                                  % reliability variables
    end
    properties (Constant, Abstract)
%         cornerLoc    % location of the corners directory
        Description    % Description of the process
%         vars_version % Release number for the variables.
    end
    properties (SetAccess = protected)
        Paths
    end
    properties (Hidden,Abstract,Access = protected)
        ModelPath
    end
    
    methods
        function ocn = OceanModelPath(obj)
            ocn{1} = ['path("' obj.Paths.unixPath('ModelPath') '" )'];
        end
        function ocn = OceanNomModelFile(obj)
        % Returns the modelFile() Ocean XL command with the nominal
        % model file section information
            ocn{1} = 'modelFile( ';
            ocnSections = cellfun(@(x) ['    ''("' x '" "' obj.NomModelFileSections(x) '")'],obj.NomModelFileSections.keys,'UniformOutput',false);
            ocn = [ocn; ocnSections'];
            ocn{end+1} = ')';
        end
        function skl = skillNomModels(obj)
            skl = cellfun(@(x) ['asiAddModelLibSelection(testSession "' obj.Paths.unixPath('ModelPath') '/' x '" "' obj.NomModelFileSections(x) '")'],obj.NomModelFileSections.keys,'UniformOutput',false);
        end
    end
    
end

