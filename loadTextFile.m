function out = loadTextFile(path)
% loadTextFile Loads a text file located at the given path.
%  Returns a cell array with each line of the file a row in the
%  cell array.
%
% USAGE
%  textFileCell = loadTextFile(path)
%
% Author: Curtis Mayberry
% Curtisma3@gmail.com
%
% See also: adexl.resultsInterface
    [fid,errorMessage] = fopen(path,'r');
    if(fid >0)
        out = textscan(fid,'%s','Delimiter',sprintf('\n'));
        out = out{1};
        fclose(fid);
    else
        disp(errorMessage);
        warning('loadTextFile:CouldNotOpen',['Could not open ' path  sprintf('\n') errorMessage]);

        out = '';
    end
end

