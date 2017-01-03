function [ varargout ] = cdsRunSkill(skillScriptFile,library,varargin)
%cdsRunSkill Runs a skill script cell array in a particular project (lib)
%   Runs a skill script contained in a cell array skillScriptCell.  First
%   the cell array is written to a file with path skillScriptFile and then
%   that skill script is executed from that path.  Each output of the 
%   script is then placed in a cell string.  The skill script must be 
%   written so each output is placed on a new line using println(output)
%
% USAGE
% outputs = cdsRunSkill(skillScriptFile,library,[skillScriptCell])
%  outputs is a cell array with each element containing a line of char 
%  output from the script
% [outputs,rawOutput] = cdsRunSkill(skillScriptFile,library,[skillScriptCell]);
%  rawOutput is the raw command line char output
% INPUTS
%  skillScriptFile - Skill script to run.  If a script cell string is
%   provided it is saved to this location, overwriting the existing script.
%   [char]
%  library - Library to run the script in. [cdsLibrary, Char]
%  skillScriptCell - cell stringwith one
%
% See Also: VirtuosoToolbox
    if(~isunix)
        error('VirtuosoToolbox:cdsRunSkill:UnixOnly','Skill functions can only be ran in unix');
    end
    % Get library name
    if(isa(library,'cdsLibrary'))
        library = library.Name;
    elseif(~ischar(library))
        error('VirtuosoToolbox:cdsRunSkill:library','Library must be a cdsLibrary or a char with the library name');
    end
    % Write the skill script to a file
    if(nargin > 2)
        fid = fopen(skillScriptFile,'w+');
        for lineNum = 1:length(varargin{1})
            fprintf(fid,'%s\n',varargin{1}{lineNum});
        end
        fclose(fid);
    end
    % Execute skill script
%     [status,rawOutput] = system(['skill ' skillScriptFile]);
    % https://community.cadence.com/cadence_technology_forums/f/48/t/13779
    % [status,rawOutput] = system(['virtuoso -nograph -replay ' skillScriptFile]);
    [status,rawOutput] = system(['cdsprj ' library 'virtuoso -nograph -restore ' skillScriptFile]);
    % [status,rawOutput] = system(['virtuoso -nograph -replay ' skillScriptFile ' -log ' logFile]);
    if(status == 0)
        output = strsplit(rawOutput,sprintf('\n'));
        if(length(output)>3)
            output = output(3:end-1);
        else
            output = {};
        end
    else
        error('VirtuosoToolbox:cdsRunSkill:scriptFail','There was an error with the script');
    end
    switch nargout
        case 1
            varargout = {output};
        case 2
            varargout = {output rawOutput};
    end
end

