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

% Log database load
Event('Querying database contents');

% Update table
set(handles.sort_menu, 'Value', 1);
handles = updateTable(handles);

% Set sort dropdown menu contents
c = get(handles.uitable1, 'ColumnName');
set(handles.sort_menu, 'String', c(1:end-2));

% Clear temporary variables
clear c;

% Disable uncompleted components
set(handles.export_button, 'Enable', 'off');
set(handles.delete_button, 'Enable', 'off');
set(handles.xls_button, 'Enable', 'off');
set(handles.filter_text, 'Enable', 'off');
set(handles.filter_check, 'Enable', 'off');

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

% Log event
Event('Updating graphical interface');

% Update table
handles = updateTable(handles);

% Clear temporary variables
clear input;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function export_button_Callback(hObject, eventdata, handles)
% hObject    handle to export_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function delete_button_Callback(hObject, eventdata, handles)
% hObject    handle to delete_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xls_button_Callback(hObject, eventdata, handles)
% hObject    handle to xls_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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
function handles = updateTable(handles)
% updateTable updates the graphical user interface table

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
};

% Query the database for all patients
[handles.database, handles.table] = QueryDatabase(handles.database, ...
    ['SELECT sopinst, ', strjoin(columns(:,1), ', '), ' FROM patients ', ...
    'ORDER BY ', columns{get(handles.sort_menu, 'Value'), 1},' ASC']);

% Define table
set(handles.uitable1, 'ColumnName', vertcat(columns(:,2), 'Files', 'Export'));
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

% Update table contents
set(handles.uitable1, 'Data', horzcat(handles.table.id, handles.table.name, ...
    handles.table.plan, handles.table.plandate, handles.table.position, ...
    handles.table.machine, handles.table.tps, handles.table.version, ...
    handles.table.type, handles.table.mode, handles.table.rxdose, ...
    handles.table.fractions, handles.table.doseperfx, cell(...
    length(handles.table.id), 1)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sort_menu_Callback(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to sort_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
c = cellstr(get(hObject,'String'));
Event(['Sort changed to ', c{get(hObject,'Value')}]);

% Query table, using new sort
handles = updateTable(handles);

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
function filter_text_Callback(hObject, eventdata, handles)
% hObject    handle to filter_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filter_text as text
%        str2double(get(hObject,'String')) returns contents of filter_text as a double


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filter_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filter_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Set background color
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filter_check_Callback(hObject, eventdata, handles)
% hObject    handle to filter_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of filter_check
