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

% Last Modified by GUIDE v2.5 23-Sep-2016 15:59:44

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


% --- Executes just before DatabaseUI is made visible.
function DatabaseUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DatabaseUI (see VARARGIN)

% Choose default command line output for DatabaseUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DatabaseUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DatabaseUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in import_button.
function import_button_Callback(hObject, eventdata, handles)
% hObject    handle to import_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in export_button.
function export_button_Callback(hObject, eventdata, handles)
% hObject    handle to export_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles)
% hObject    handle to delete_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in xls_button.
function xls_button_Callback(hObject, eventdata, handles)
% hObject    handle to xls_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
