% Test1_AC_1pD.vcsv
close all;
clear all;

%
% File information
%
FOLDER = 'D:\Documents\My Documents\My Homework(Fall 2014)\Simulation Results\Results-GTBEA_v1R_2\TOP_v1R_2_OL_9-28-14';
FILENAME = 'TOP_v1R_2_OL_TRANS.vcsv';

% Parse Data
[freqs, voltage, signalNames, units] = virtuoso_importVCSV_TRANS(FOLDER, FILENAME);

% Plot Data
figure;
plot(freqs(:,2), abs(voltage(:,2)));

xlabel(['Frequency (' char(units{1}) ')'])
ylabel('Magnitude (V)');
title(char(signalNames{1}),'Interpreter', 'none');

figure;
plot(freqs(:,2), 20*log(abs(voltage(:,2))));

xlabel(['Time (' char(units{3}) ')'])
ylabel('Magnitude (dB)');
title(char(signalNames{2}),'Interpreter', 'none');

