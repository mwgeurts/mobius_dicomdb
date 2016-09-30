function handles = UpdateTable(handles)
% UpdateTable updates the graphical user interface table

% Define columns
columns = {
    'id', 'ID'
    'name', 'Name'
    'plan', 'Plan'
    'plandate', 'Plan Date'
    'position', 'Position'
    'machine', 'Machine'
    'tps', 'TPS'
    'version', 'Version'
    'type', 'Type'
    'mode', 'Mode'
    'rxdose', 'Dose'
    'fractions', 'Fractions'
    'doseperfx', 'Dose/Fx'
    'numfiles', 'Files'
};

% Query the database for all patients
[handles.database, handles.table] = QueryDatabase(handles.database, ...
    ['SELECT sopinst, ', strjoin(columns(:,1), ', '), ' FROM patients ', ...
    'ORDER BY ', columns{get(handles.sort_menu, 'Value'), 1},' ASC']);

% Apply filter, if present
if ~isempty(handles.table.sopinst) && ...
        get(handles.filter_check, 'Value') == 1 && ...
        ~isempty(get(handles.filter_text, 'String'))
    
    % Initialize matches vector
    m = zeros(length(handles.table.sopinst), 1);
    
    % Loop through columns
    for i = 1:size(columns,1)
        
        % If column is text
        if ischar(handles.table.(columns{i,1}){1})

            % Apply filter to column
            m = m + 1 - cellfun(@isempty, ...
                regexpi(handles.table.(columns{i,1}), ...
                get(handles.filter_text, 'String')));
        end
    end
    
    % Remove sopinstances that didn't match
    handles.table.sopinst(m == 0) = [];
    
    % Loop through columns
    for i = 1:size(columns,1)

        % Remove rows that didn't match
        handles.table.(columns{i,1})(m == 0) = [];
    end
end

% Define table
set(handles.uitable1, 'ColumnName', vertcat(columns(:,2), 'Export'));
set(handles.uitable1, 'ColumnEditable', logical(horzcat(zeros(1, ...
    length(get(handles.uitable1, 'ColumnName'))-1), 1)));
set(handles.uitable1, 'ColumnFormat', horzcat(cell(1, ...
    length(get(handles.uitable1, 'ColumnName'))-1), 'Logical'));

% Format dates
for i = 1:length(handles.table.plandate)
    handles.table.plandate{i} = datestr(handles.table.plandate{i});
end

% Format doses/fractions
for i = 1:length(handles.table.rxdose)
    handles.table.fractions{i} = sprintf('%i', handles.table.fractions{i});
    
    if handles.table.rxdose{i} == 0
        handles.table.rxdose{i} = '';
        handles.table.doseperfx{i} = '';
    else
        handles.table.rxdose{i} = ...
            sprintf('%0.1f Gy', handles.table.rxdose{i});
        handles.table.doseperfx{i} = ...
            sprintf('%0.1f Gy', handles.table.doseperfx{i});
    end
end

% Format number of files
for i = 1:length(handles.table.numfiles)
    handles.table.numfiles{i} = sprintf('%i', handles.table.numfiles{i});
end

% Generate display table
t = cell(length(handles.table.sopinst), size(columns,1)+1);
for i = 1:size(columns,1)
    t(:,i) = handles.table.(columns{i,1});
end

% Update table contents
set(handles.uitable1, 'Data', t);

% Clear temporary variables
clear i m t columns;