classdef cdsAdexl
    %cdsAdexl An ADE-XL state
    %   An Ades-XL state that can be written to a 
    
    properties
        cell
        outputs
        tests
        corners
        globalVars
    end
    
    methods
        function obj = cdsAdexl(cell)
            obj.cell.name = cellName;
        end
        function addTest(test)
            
        end
        function writeADEXLstate(file)
            
        end
        function writeOutputs(file)
            
        end
    end
    
end

