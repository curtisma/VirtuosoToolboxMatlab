% virtuoso_importVCSV_AC
%  imports AC analysis data that is saved in a .vcsv file from Cadence Virtuoso
%   [time, voltage, signalNames, units] = virtuoso_importVCSV_TRANS(folder, filename)  
%   
%   Inputs: 
%    folder - The folder in which the data file is saved
%    filename - name of the .vcsv file to be imported
%   Outputs: 
%    time - time points of the transient data.  One trace per column
%    voltage - voltage data.  One trace per column
%    signalNames - Names of the signals to be saved
%    units - units of each trace. Two columns per trace.
% 
%   Note: To save to .vcsv in Cadence virtuoso go to Trace -> save when you 
%   have the traces you want to save selected.  (Can use Trace -> select all)
% 
function [time, voltage, signalNames, units] = virtuoso_importVCSV_TRANS(folder, filename)

FID = fopen(fullfile(folder, filename));

% Parse Header
[~] = fgetl(FID);% version = fgetl(FID);
if(strcmp(version, ';Version, 1, 0'))
    warning('VirtuosoToolBox:virtuoso_importVCSV_TRANS:versionNotSupported','The version of the vcsv file used is not supported')
end
signalNames = fgetl(FID);
[~] = fgetl(FID); % axes = fgetl(FID);
[~] = fgetl(FID);      % dataType = fgetl(FID);
[~] = fgetl(FID); % dataInfo = fgetl(FID);
units = fgetl(FID);
numSignals = length(strfind(signalNames, ';'));


% parse data
format_str = ones(numSignals-1,1)*'%f,%f,';
format_str = [char(reshape(format_str',1,[])) '%f,%f'];
Data = textscan(FID,format_str);

units(units == ';' | units == ',') = '	';
format_str_units = ones(numSignals,1)*'%s %s ';
format_str_units = char(reshape(format_str_units',1,[]));
units = textscan(units,format_str_units);

signalNames(signalNames == ',') = ' ';
format_str_signalNames = ones(numSignals,1)*'%s ';
format_str_signalNames = char(reshape(format_str_units',1,[]));
signalNames = textscan(signalNames,'%s','Delimiter',';');
signalNames{1}(1) = []; % Remove empty first element (lines start with ';')

fclose(FID);

% Package data into matricees
time = cell2mat(Data(1:2:end));
voltage = cell2mat(Data(2:2:end));