classdef cellview
    %adexl.cellview An ADE-XL cellview
    %   An cellview
    
    properties
        cell
        outputs
        tests
        corners
        globalVars
    end
    
    methods
        function obj = cdsAdexl(cell,varargin)
            obj.cell.name = cellName;
        end
        function loadSTC(STC,varargin)
            % Load Tests
            %  Each test is a line in the STC file
            
        end
        function addTest(test)
            
        end
        function writeADEXLstate(file)
            
        end
        function writeOutputs(file)
            
        end
    end
    
end

