classdef cdsRunSkillTest < matlab.unittest.TestCase
    %cdsRunSkillTest Tests the cdsRunSkill function
    %   Tests covers the following items:
    %   * skill script creation
    %   * skill script execution
    %
    % See Also: cdsRunSkill
    
    properties
    end
    
    methods (Test,TestTags={'Unit'})
    end
    methods (Test,TestTags={'Integration','CadenceIntegration'})
        function testCreateAndExecuteScript(testCase)
            scriptSaveLoc = which('cdsRunSkill');
            exampleScript = {'println("hello world")'; 'println("Test output 2")'};
            output = cdsRunSkill([scriptSaveLoc(1:end-14) filesep 'cdsRunSkillTestScript.cxt'],exampleScript);
            testCase.verifyTrue(strcmp(output{1},'"hello world"'));
            testCase.verifyTrue(strcmp(output{2},'"Test output 2"'));
        end
        function testCreateAndExecuteScript2outputs(testCase)
            scriptSaveLoc = which('cdsRunSkill');
            exampleScript = {'println("hello world")'; 'println("Test output 2")'};
            [output, rawOut] = cdsRunSkill([scriptSaveLoc(1:end-14) filesep 'cdsRunSkillTestScript.cxt'],exampleScript);
            testCase.verifyTrue(strcmp(output{1},'"hello world"'));
            testCase.verifyTrue(strcmp(output{2},'"Test output 2"'));
            testCase.verifyClass(rawOut,'char');
        end
    end
    
end

