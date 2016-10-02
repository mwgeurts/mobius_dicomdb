function varargout = DatabaseUI(varargin)
% DATABASEUI MATLAB code for DatabaseUI.fig
%      DATABASEUI, by itself, creates a new DATABASEUI or raises the existing
%      singleton*.
%
%      H = DATABASEUI returns the handle to a new DATABASEUI or the handle to
%      the existing singleton*.
%
%      DATABASEUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DATABASEUI.M with the given input arguments.
%
%      DATABASEUI('Property','Value',...) creates a new DATABASEUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DatabaseUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DatabaseUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DatabaseUI

% Last Modified by GUIDE v2.5 28-Sep-2016 20:03:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DatabaseUI_OpeningFcn, ...
                   'gui_OutputFcn',  @DatabaseUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DatabaseUI_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DatabaseUI (see VARARGIN)

% Turn off MATLAB warnings
warning('off', 'all');

% Choose default command line output for DatabaseUI
handles.output = hObject;

%% Set Version Info
% Set version handle
handles.version = '0.9';
set(handles.version_text, 'String', ['Version ', handles.version]);

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Store and set current directory to location of this application
cd(path);
handles.path = path;

% Clear temporary variable
clear path;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

%% Initialize Event Log
% Store program and MATLAB/etc version information as a string cell array
string = {'Mobius Anonymized DICOM Database'
    sprintf('Version: %s (%s)', handles.version, handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Clear temporary variables
clear separator;

% Log information
Event(string, 'INIT');

%% Load Submodules
% Add mobius_query submodule to search path
addpath('./mobius_query');

% Check if MATLAB can find EstablishConnection
if exist('EstablishConnection', 'file') ~= 2
    
    % If not, throw an error
    Event(['The mobius_query submodule does not exist in the search path. ', ...
        'Use git clone --recursive or git submodule init followed by git ', ...
        'submodule update to fetch all submodules'], 'ERROR');
end

% Add jsonlab folder to search path
addpath('./mobius_query/jsonlab');

% Check if MATLAB can find loadjson
if exist('loadjson', 'file') ~= 2
    
    % If not, throw an error
    Event(['The mobius_query/jsonlab/ submodule is missing. Download it ', ...
        'from the MathWorks.com website'], 'ERROR');
end

% Add dicom_tools submodule to search path
addpath('./dicom_tools');

% Check if MATLAB can find LoadJSONPlan
if exist('LoadJSONPlan', 'file') ~= 2
    
    % If not, throw an error
    Event(['The dicom_tools submodule does not exist in the search path. ', ...
        'Use git clone --recursive or git submodule init followed by git ', ...
        'submodule update to fetch all submodules'], 'ERROR');
end

%% Load Configuration File
% Open file handle to config.txt file
fid = fopen('config.txt', 'r');

% Verify that file handle is valid
if fid < 3
    
    % If not, throw an error
    Event(['The config.txt file could not be opened. Verify that this ', ...
        'file exists in the working directory. See documentation for ', ...
        'more information.'], 'ERROR');
end

% Scan config file contents
c = textscan(fid, '%s', 'Delimiter', '=');

% Close file handle
fclose(fid);

% Loop through textscan array, separating key/value pairs into array
for i = 1:2:length(c{1})
    handles.config.(strtrim(c{1}{i})) = strtrim(c{1}{i+1});
end

% Clear temporary variables
clear c i fid;

% Log completion
Event('Loaded config.txt parameters');

%% Load Database
% Log database load
Event('Initializing database');

% Execute LoadDatabase
handles.database = LoadDatabase(handles.config.SQLITE3_DATABASE);

% Rescan DICOM folder
handles = ScanFiles(handles);

% Log database load
Event('Querying database contents');

% Update table
set(handles.sort_menu, 'Value', 1);
handles = UpdateTable(handles);

% Set sort dropdown menu contents
c = get(handles.uitable1, 'ColumnName');
set(handles.sort_menu, 'String', c(1:end-1));

% Clear temporary variables
clear c;

% Clear filter
set(handles.filter_text, 'String', '');
set(handles.filter_check, 'Value', 0);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = DatabaseUI_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function import_button_Callback(hObject, ~, handles)
% hObject    handle to import_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('User selected to import new archives');
Event('Prompting for server information');

% Open a ui prompt to ask for Mobius3D server
input = inputdlg({'Enter Mobius3D server to query:', 'Enter username:', ...
    'Enter Password:'}, 'Mobius3D Inputs', [1 30], ...
    {handles.config.MOBIUS_SERVER, handles.config.MOBIUS_USER, ...
    handles.config.MOBIUS_PASS});

% Log event
Event('Establishing connection to server');

% Establish connection to server
handles.session = EstablishConnection('server', input{1}, 'user', input{2}, ...
    'pass', input{3});

% Execute ImportData
[handles.session, handles.database] = ImportData('server', input{1}, ...
    'session', handles.session, 'database', handles.database, 'directory', ...
    handles.config.DICOM_FOLDER);

% Rescan DICOM folder
handles = ScanFiles(handles);

% Log event
Event('Updating graphical interface');

% Update table
handles = UpdateTable(handles);

% Clear temporary variables
clear input;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function export_button_Callback(hObject, ~, handles)
% hObject    handle to export_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('User selected to export selected rows');

% Retrieve the UI table contents
t = get(handles.uitable1, 'Data');

% Prompt user to select a destination folder
Event('Prompting user to select destination folder');
path = uigetdir(handles.path, 'Select directory to export DICOM files to');

% If user cancelled
if path == 0
    Event('User cancelled folder selection');
    return;
end

% Initialize counter
c = 0;

% Loop through the table rows
for i = 1:length(handles.table.sopinst)
    
    % If the row is selected
    if t{i,end} == 1
        
        % Increment counter
        c = c + 1;
        
        % Log deletion
        Event(['Exporting SOP instance ', handles.table.sopinst{i}]);
        
        % Copy folder to destination
        [s, m] = copyfile(fullfile(handles.config.DICOM_FOLDER, ...
            handles.table.sopinst{i}), fullfile(path, ...
            handles.table.sopinst{i}));
        
        % Inform the user that the directory could not be deleted
        if s == 0
            Event(['The DICOM folder ', ...
                fullfile(handles.config.DICOM_FOLDER, ...
                handles.table.sopinst{i}), ' could not be copied to ', ...
                path,': ', m], 'ERROR');
        end
    end
end

% Log event
Event(sprintf('Export completed, copying %i plans to %s', c, path));

% Clear temporary variables
clear c i m s t path;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function delete_button_Callback(hObject, ~, handles)
% hObject    handle to delete_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('User selected to delete selected rows');

% Retrieve the UI table contents
t = get(handles.uitable1, 'Data');

% Loop through the table rows
for i = 1:length(handles.table.sopinst)
    
    % If the row is selected
    if t{i,end} == 1
        
        % Log deletion
        Event(['Deleting SOP instance ', handles.table.sopinst{i}]);
        
        % Remove entry from table
        handles.dastabase = QueryDatabase(handles.database, ...
            ['DELETE FROM patients WHERE sopinst = ''', ...
            handles.table.sopinst{i}, '''']);
        
        % Try to remove the table
        [s, m, ~] = rmdir(fullfile(handles.config.DICOM_FOLDER, ...
            handles.table.sopinst{i}), 's');
        
        % Inform the user that the directory could not be deleted
        if s == 0
            Event(['The subdirectory ', fullfile(handles.config.DICOM_FOLDER, ...
                handles.table.sopinst{i}), ' could not be deleted: ', ...
                m], 'ERROR');
        end
    end
end

% Log event
Event('Updating graphical interface');

% Update table
handles = UpdateTable(handles);

% Clear temporary variables
clear i m s t;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xls_button_Callback(~, ~, handles)
% hObject    handle to xls_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('User selected Excel export');

% Prompt user to select save file
Event('Prompting user to select destination file');
[file, path] = uiputfile({'CSV File', '*.csv'}, 'Save Excel File');

% If user specified a value
if ~isempty(file) && ischar(file)
    
    % Log choice
    Event(['User chose to save table to ', fullfile(path, file)]);
    
    % Initialize empty cell array
    f = fieldnames(handles.table);
    t = cell(length(handles.table.sopinst), length(f));
    
    % Loop through table columns
    for i = 1:length(f)

        % Store rows
        t(:,i) = handles.table.(f{i});
    end
    
    % Attempt to write to output file
    try
        writetable(cell2table(t, 'VariableNames', f), fullfile(path, file));
        
        % Log completion
        Event(['Table successfully exported to ', fullfile(path, file)]);
    
    % Otherwise, log an error
    catch
        Event(['Error writing to file ', fullfile(path, file)], 'ERROR');
    end
    
% Log cancel
else
    Event('User cancelled Excel export');
end

% Clear temporary variables
clear f i t file path;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figure1_CloseRequestFcn(hObject, ~, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('Closing the database connection');

% Close the database
close(handles.database);

% Hint: delete(hObject) closes the figure
delete(hObject);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sort_menu_Callback(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to sort_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
c = cellstr(get(hObject,'String'));
Event(['Sort changed to ', c{get(hObject,'Value')}]);

% Query table, using new sort
handles = UpdateTable(handles);

% Update handles structure
guidata(hObject, handles);

% Clear temporary variables
clear c;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sort_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to sort_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set background color
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filter_text_Callback(hObject, ~, handles)
% hObject    handle to filter_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check if filter is enabled
if get(handles.filter_check, 'Value') == 1

    % Revert to default text if empty
    if isempty(get(hObject, 'String'))

        % Log event
        Event('Filter cleared');

    else

        % Log event
        Event(['Filter changed to ', get(hObject,'String')]);
    end

    % Query table, using new sort
    handles = UpdateTable(handles);

    % Update handles structure
    guidata(hObject, handles);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filter_text_CreateFcn(hObject, ~, ~)
% hObject    handle to filter_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set background color
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filter_check_Callback(hObject, ~, handles)
% hObject    handle to filter_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Revert to default text if empty
if get(hObject, 'Value') == 1
    
    % Log event
    Event('Filter enabled');
else
    
    % Log event
    Event('Filter disabled');
end

% Query table, using new sort
handles = UpdateTable(handles);

% Update handles structure
guidata(hObject, handles);