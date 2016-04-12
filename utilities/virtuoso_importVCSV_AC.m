% virtuoso_importVCSV_AC
%  imports transient analysis data that is saved in a .vcsv file from Cadence Virtuoso
%   [freqs, voltage, signalNames, units] = virtuoso_importVCSV_AC(folder, filename)  
%   
%   Inputs: 
%    folder - The folder in which the data file is saved
%    filename - name of the .vcsv file to be imported
%   Outputs: 
%    freqs - frequency points of the AC data.  One trace per column
%    voltage - complex voltage data.  One trace per column
%    signalNames - Names of the signals to be saved
%    units - units of each trace. Two columns per trace.
% 
%   Note: To save to .vcsv in Cadence virtuoso go to Trace -> save when you 
%   have the traces you want to save selected.  (Can use Trace -> select all)
function [freqs, voltage, signalNames, units] = virtuoso_importVCSV_AC(folder, filename)

FID = fopen(fullfile(folder, filename));

% Parse Header
[~] = fgetl(FID);% version = fgetl(FID);
if(strcmp(version, ';Version, 1, 0'))
    warning('VirtuosoToolBox:virtuoso_importVCSV_AC:versionNotSupported','The version of the vcsv file used is not supported')
end
signalNames = fgetl(FID);
[~] = fgetl(FID); % axes = fgetl(FID);
[~] = fgetl(FID);      % dataType = fgetl(FID);
[~] = fgetl(FID); % dataInfo = fgetl(FID);
units = fgetl(FID);
numSignals = length(strfind(signalNames, ';'));


% parse data
format_str = ones(numSignals-1,1)*'"%f","%f","%f",';
format_str = [char(reshape(format_str',1,[])) '"%f","%f","%f"'];
Data = textscan(FID,format_str);

units(units == ';' | units == ',') = '	';
format_str_units = ones(numSignals,1)*'%s %s ';
format_str_units = char(reshape(format_str_units',1,[]));
units = textscan(units,format_str_units);

signalNames(signalNames == ';' | signalNames == ',') = ' ';
format_str_signalNames = ones(numSignals,1)*'%s ';
format_str_signalNames = char(reshape(format_str_signalNames',1,[]));
signalNames = textscan(signalNames,format_str_signalNames);

fclose(FID);

% Package data into matricees
freqs = cell2mat(Data(1:3:end));
DataReal = cell2mat(Data(2:3:end));
DataImag = cell2mat(Data(3:3:end));
voltage = complex(DataReal, DataImag);
