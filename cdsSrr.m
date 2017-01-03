function sigs = cdsSrr(varargin)
%cdsSrr Loads data from the Cadence database
%   Requirements:
%   * Must be ran in Linux
%   * Cadence RF toolbox must be added to the MATLAB path
%   * Licensing for Cadence Spectre RF must be setup
% 
% USAGE
%  simInfo = obj.cdsSrr(psfPath, analysis)
%   Loads the list of available analyses
%  simInfo = obj.cdsSrr(psfPath, analysis)
%   Loads information about the simulation.  simInfo is a structure
%   which contains data about the analysis
%  simData = obj.cdsSrr(psfPath,analysis,signal);
%   Loads a specific signal
% See also: cds_srr, VirtuosoToolbox
    if(strcmpi(varargin{1},'test_dc'))
        switch nargin
            case 1
                sigs = {'dcOp-dc'; 'dcOpInfo-info';'dc-dc';'modelParameter-info';'element-info';'outputParameter-info';'designParamVals-info';'primitives-info.primitives';'subckts-info.subckts';'asserts-info.assert';'variables'};
            case 2
                sigs = struct('signal_info',{'prop'  'Unknown'  'V'  'Real'  'I'  'Real'  'eumm'  'Real'},...
                              'prop',{'PSFversion','BINPSF creation time','PSF style','PSF types','PSF sweeps','PSF sweep points','PSF sweep min','PSF sweep max','PSF groups','PSF traces'
    'simulator'
    'version'
    'date'
    'design'
    'analysis type'
    'analysis name'
    'analysis description'
    'xVecSorted'
    'tolerance.relative'
    'reltol'
    'abstol(V)'
    'abstol(I)'
    'abstol(Temp)'
    'abstol(Pwr)'
    'temp'
    'tnom'
    'tempeffects'
    'gmindc'
        end
    elseif(~ispc)
        switch nargin
            case 1
                [~,sigs] = evalc(sprintf('cds_srr(%s)',varargin{1}));
            case 2
                [~,sigs] = evalc(sprintf('cds_srr(%s,%s)',varargin{1},varargin{2}));
            case 3
                [~,sigs] = evalc(sprintf('cds_srr(%s,%s,%s)',varargin{1},varargin{2},varargin{3}));
            otherwise
                error('VirtuosoToolbox:cdsSrr:numInputs','Wrong Number of Inputs')
        end
    else
        error('VirtuosoToolbox:cdsSrr:UnixOnly','The spectre RF toolbox only works in linux');
    end
end

