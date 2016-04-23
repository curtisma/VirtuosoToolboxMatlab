%MLAB2PWL Create a Cadence PWL compatible file.
%   MLAB2PWL(TIME,SIGNAL,[FILENAME]) creates a file named FILENAME
%   that consists of the TIME and SIGNAL data in a format
%   compatible with Cadence PWL sources
%
%   FILENAME is optional and if not supplied, "pwl.txt" will be used

%   Copyright 2008 David Freedman 
%   $Revision: 1.00 $  $Date: 2008/05/29 18:15:22 $

function mlab2pwl (time, signal, filename)
cont = 1;
if nargin < 3 
    filename = 'pwl.txt';
end
if nargin < 2
    disp('A minimum of two signals must be supplied. Exiting!');
    cont = 0;
end
if (length(time) ~= length(signal))
    disp('Both signals must be the same length. Exiting!');
    cont = 0;
end  

if (cont == 1) 
    pwlfile = fopen(filename,'w');
    for i = 1:length(time)
        fprintf(pwlfile, '%e %e\n',time(i),signal(i));
    end
    fclose(pwlfile);
    disp(['Created file ' filename ' containing ' ...
        num2str(length(time)) ' data points']);
end