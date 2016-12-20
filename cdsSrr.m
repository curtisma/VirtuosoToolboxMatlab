function sigs = cdsSrr(varargin)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
% cdsSrr Loads data from the Cadence database
% 
% USAGE
%  simInfo = obj.cdsSrr(corner)
%   Loads information about the simulation.  simInfo is a structure
%    which contains data about the analysis
%  simData = obj.cdsSrr(corner,signal);
%   Loads a specific signal
% See also: cds_srr, VirtuosoToolbox
    if(strcmpi(varargin{1},'test'))
        
    else
        switch nargin
            case 1
                [~,sigs] = evalc(sprintf('cds_srr(%s)',varargin{1}));
            case 2
                [~,sigs] = evalc(sprintf('cds_srr(%s,%s)',varargin{1},varargin{2}));
            case 3
                [~,sigs] = evalc(sprintf('cds_srr(%s,%s,%s)',varargin{1},varargin{2},varargin{3}));
            otherwise
                error('VirtuosoToolbox:cdsSrr','Wrong Number of Inputs')
        end
    end
end

