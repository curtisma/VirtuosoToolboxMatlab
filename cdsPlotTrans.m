function [ trans ] = cdsPlotTrans( name, stripNum, numStrips )
%cdsPlotTrans Plots a transient Cadence signal
%   Detailed explanation goes here
%   
%  trans = cdsPlotTrans(name,stripNum,numStrips)
% 
% INPUTS
%  name - signal name
%  stripNum - The strip number with the top strip being strip 1
%  numStrips - The number of strips
%
% OUTPUTS
%  trans - transient data as a structure with the signal name as the field
%  
% TO DO
% Need to add support for corner sims and transient currents
%
% see also skyVer
if(isunix && exist(axlCurrentResultsPath,'var'))
    trans.(name) = cds_srr( axlCurrentResultsPath, 'tran-tran',name);
end

% Plot
subplot(numStrips,1,stripNum);
hold on;
plot( trans.(name).time*1000,trans.(name).V );
hold off;
xlabel('time (ms)');
ylabel([name ' (V)']);

end

