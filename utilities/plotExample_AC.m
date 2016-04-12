% Test1_AC_1pD.vcsv
close all;
clear all;

%
% File information
%
FOLDER = 'D:\Documents\My Documents\My Homework(Fall 2014)\Simulation Results\Results - GTBE-A_Device_FT_no_cancellation_test\';
FILENAME = 'Test1_AC_1pF.vcsv';

% Parse Data
[freqs, voltage, signalNames, units] = virtuoso_importVCSV_AC(FOLDER, FILENAME);

% Plot Data
figure;
semilogx(freqs(:,2), abs(voltage(:,2)));

title(char(signalNames{2}),'Interpreter', 'none');
xlabel(['frequency (' char(units{1}) ')'])
ylabel('magnitude (V)');

figure;
semilogx(freqs(:,2), 20*log(abs(voltage(:,2))));

title(char(signalNames{2}),'Interpreter', 'none');
xlabel(['frequency (' char(units{1}) ')'])
ylabel('magnitude (dB)');

