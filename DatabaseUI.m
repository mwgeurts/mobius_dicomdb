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

% Last Modified by GUIDE v2.5 23-Sep-2016 16:50:02

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

% Add mobius_query submodule to search path
addpath('./mobius_query');

% Check if MATLAB can find CalcGamma
if exist('EstablishConnection', 'file') ~= 2
    
    % If not, throw an error
    Event(['The mobius_query submodule does not exist in the search path. Use ', ...
        'git clone --recursive or git submodule init followed by git ', ...
        'submodule update to fetch all submodules'], 'ERROR');
end

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

% Log database load
Event('Initializing database');

% Execute LoadDatabase
handles.database = LoadDatabase(handles.config.SQLITE3_DATABASE);

% Log database load
Event('Querying database contents');

% Query the database for all patients
table = QueryDatabase(handles.database, ['SELECT uid, plan, plandate, ', ...
    'machine, tps, version, type, mode, rxdose, fractions, doseperfx, ', ...
    'position FROM patients ORDER BY plan ASC']);

% Define table
set(handles.uitable1, 'ColumnName', {'Plan', 'Plan Date', 'Position', ...
    'Machine', 'TPS', 'Version', 'Type', 'Mode', 'Rx Dose', 'Fractions', ...
    'Dose/Fx'});
set(handles.uitable1, 'ColumnEditable', logical(zeros(1, ...
    length(get(handles.uitable1, 'ColumnName'))))); %#ok<LOGL>

% Update table contents
set(handles.uitable1, 'Data', horzcat(table.plan, table.plandate, ...
    table.position, table.machine, table.tps, table.version, table.type, ...
    table.mode, table.rxdose, table.fractions, table.doseperfx));

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
function import_button_Callback(hObject, eventdata, handles)
% hObject    handle to import_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



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
