classdef variablesTest < matlab.unittest.TestCase
    %variablesTest Tests the adexl.variables class
    %   Tests covers the following items:
    %   * Object Creation
    %   * Each method
    %
    % See Also: adexl.variables
    
    properties
    end
    
    methods (Test,TestTags={'Unit'})
        function testAddAtConstruction(testCase)
            var = adexl.variables('VDD',3:0.5:5.0, 'VIO',[1.65 1.8 1.95]);
            testCase.verifyEqual(var.VDD,3:0.5:5.0);
            testCase.verifyEqual(var.VIO,[1.65 1.8 1.95]);
        end
        function testAddVariables(testCase)
            var = adexl.variables;
            var.add('VDD',3:0.5:5.0);
            var.add('VIO',[1.65 1.8 1.95]);
            testCase.verifyEqual(var.VDD,3:0.5:5.0);
            testCase.verifyEqual(var.VIO,[1.65 1.8 1.95]);
        end
        function testRemoveVariables(testCase)
            var = adexl.variables('VDD',3:0.5:5.0, 'VIO',[1.65 1.8 1.95]);
            var.remove('VDD');
            testCase.verifyError(@var.VDD,'MATLAB:noSuchMethodOrField');
        end
        function testNumVars(testCase)
            var = adexl.variables('VDD',3:0.5:5.0, 'VIO',[1.65 1.8 1.95]);
            testCase.verifyEqual(var.numVars,2);
        end
        function testVariableNames(testCase)
            var = adexl.variables('VDD',3:0.5:5.0, 'VIO',[1.65 1.8 1.95]);
            testCase.verifyEqual(var.variableNames,{'VDD';'VIO'});
        end
        function testExport(testCase)
            var = adexl.variables('VDD',3:0.5:5.0, 'VIO',[1.65 1.8 1.95]);
            XMLdoc = var.export;
            testCase.verifyClass(var.export,'org.apache.xerces.dom.DocumentImpl')
        end
        function testCopy(testCase)
            var = adexl.variables('VDD',3:0.5:5.0, 'VIO',[1.65 1.8 1.95]);
            varCopy = var.copy;
            testCase.verifyEqual(varCopy.variableNames,{'VDD';'VIO'});
        end
%         function testImport(testCase)
%             var = adexl.variables;
%             var.import(psfdir);
%             testCase.verifyEqual(var.VDD,3:0.5:5.0);
%             testCase.verifyEqual(var.VIO,[1.65 1.8 1.95]);
%         end
%         function testImportAtConstruction(testCase)
%             
%         end
    end
    methods (Test,TestTags={'Integration','CadenceIntegration'})
    end
    
end

