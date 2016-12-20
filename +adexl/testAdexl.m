% adexl Test suite
% Author: Curtis Mayberry
import matlab.unittest.TestSuite


% Class unit tests
% varTest = adexl.variablesTest;
% testResults = varTest.run

% Run all tests in the package
adexlTestSuite = TestSuite.fromPackage('adexl');
testResults = adexlTestSuite.run
