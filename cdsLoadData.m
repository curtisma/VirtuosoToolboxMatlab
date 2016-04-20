function varargout  = cdsLoadData(filePath)
%cdsLoadData Loads a CSV data file simulated using Cadence ADEXL
%   The data can come out as one or two data tables:
%   
%   data = cdsLoadData(filePath);
%    Data Table
%    rows: corner name
%    variables: corners variables and outputs
%
%   [outputs corners] = cdsLoadData(filePath);
%    Outputs Table
%    rows: output name
%    variables: output data over corners and spec data
%    Corners Table
%    rows: corner name
%    variables: corner parameters
%
%  See Also: cdsAdexl

    fid = fopen(filePath);
    disp(['opened data file: ' filePath]);
    
    txt = textscan(fid,'%s','ReturnOnError',false);
    txt = cellfun(@(x) strsplit(char(x),',','CollapseDelimiters',false),txt{1},'UniformOutput',false);
    txt = cellfun(@(x) x',txt','UniformOutput' ,false);
    txt = [txt{:}];
    i_header = strcmp(txt(1,:),'Test');

    if(nargout == 1)
        deleteRows = strcmp(txt(:,i_header),'Pass/Fail') | ...
                     strcmp(txt(:,i_header),'Weight') | ...
                     strcmp(txt(:,i_header),'Spec') | ...
                     strcmp(txt(:,i_header),'Min') | ...
                     strcmp(txt(:,i_header),'Max');
        deleteRows(1) = true;
        txt(deleteRows,:) = [];
        txt(:,strcmp(txt(1,:),'Output')) = [];
        header = txt(1,:);
        txt(1,:) = [];
        header{strcmp(header,'Parameter')} = 'Corner';
        numericalCols = cellfun(@(x) ~isnan(str2double(x)),txt(1,:));
        txt(:,numericalCols) = cellfun(@str2double,txt(:,numericalCols), 'UniformOutput', false);
        if(any(cellfun(@(x) strcmp(x,'header_MIPI.scs'),header(2:end))))
            header{cellfun(@(x) strcmp(x,'header_MIPI.scs'),header)} = 'Process';
        end
        varargout = {cell2table(txt(:,2:end),'VariableNames',header(2:end),...
                                'RowNames',txt(:,1))};
        varargout{1}.Properties.DimensionNames = {'Corner','Variable'};
        varargout{1}.Properties.Description = 'Simulation Data';
    elseif(nargout == 2)
        % Seperate corners and outputs
        corners = txt(:,1:find(i_header)-1);
        outputs = txt(:,find(i_header):end)';        
        
        % Process corners
        corners(cellfun(@isempty,corners(:,1)),:) = [];
        cVarNames = corners(1,2:end);
        cNames = corners(2:end,1);
        numericalCols = cellfun(@(x) ~isnan(str2double(x)),corners(2,:));
        corners(2:end,numericalCols) = cellfun(@str2double,corners(2:end,numericalCols), 'UniformOutput', false);
        corners = cell2table(corners(2:end,2:end),...
                  'VariableNames',cVarNames,'RowNames',cNames);
        corners.Properties.DimensionNames = {'Corner','Variable'};
        corners.Properties.Description = 'Simulation Corners';
        
        % Process Outputs
        oHeader = outputs(1,:);
        oHeader{strcmp(oHeader,'Pass/Fail')} = 'Pass_Fail';
        outputs(1,:) = [];
        numericalCols = cellfun(@(x) ~isnan(str2double(x)),outputs(1,:));
        outputs(:,numericalCols) = cellfun(@str2double,outputs(:,numericalCols), 'UniformOutput', false);
        outputs = cell2table(outputs(:,[1 3:end]),'VariableNames',oHeader([1 3:end]),'RowNames',outputs(:,2));
        outputs.Pass_Fail = categorical(outputs.Pass_Fail);
        outputs.Test = categorical(outputs.Test);
        outputs.Properties.DimensionNames = {'Output','Variable'};
        outputs.Properties.Description = 'Simulation Outputs';
        
        varargout = {outputs corners};
    end
    fclose(fid);
end

