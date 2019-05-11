function varargout = randomTestGui(varargin)
%RANDOMTESTGUI MATLAB code file for randomTestGui.fig
%      RANDOMTESTGUI, by itself, creates a new RANDOMTESTGUI or raises the existing
%      singleton*.
%
%      H = RANDOMTESTGUI returns the handle to a new RANDOMTESTGUI or the handle to
%      the existing singleton*.
%
%      RANDOMTESTGUI('Property','Value',...) creates a new RANDOMTESTGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to randomTestGui_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      RANDOMTESTGUI('CALLBACK') and RANDOMTESTGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in RANDOMTESTGUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help randomTestGui

% Last Modified by GUIDE v2.5 24-Apr-2019 17:51:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @randomTestGui_OpeningFcn, ...
                   'gui_OutputFcn',  @randomTestGui_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before randomTestGui is made visible.
function randomTestGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for randomTestGui
handles.output = hObject;
if strcmp(varargin{1}, 'model_full_path')
    model_full_path = varargin{2};
else
    display_msg('USE: randomTestGui(''model_full_path'',''path_to_model'');',...
        MsgType.ERROR, 'random_test_gui', '');
    errordlg('USE: randomTestGui(''model_full_path'',''path_to_model'');');
    return;
end
data = struct('model_full_path', model_full_path,...
    'nb_steps', 100,...
    'min', -100, ...
    'max', 100, ...
    'export2ws', 0, ...
    'mkharness', 0);
set(handles.uipanel1, 'UserData', data);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes randomTestGui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = randomTestGui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function nb_steps_Callback(hObject, eventdata, handles)
% hObject    handle to nb_steps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nb_steps as text
%        str2double(get(hObject,'String')) returns contents of nb_steps as a double
data = get(handles.uipanel1,'UserData');
data.nb_steps =  str2double(get(hObject,'String')) ;
set(handles.uipanel1,'UserData',data);

% --- Executes during object creation, after setting all properties.
function nb_steps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nb_steps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && strcmp(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save2ws.
function save2ws_Callback(hObject, eventdata, handles)
% hObject    handle to save2ws (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of save2ws
data = get(handles.uipanel1,'UserData');
data.export2ws =   get(hObject,'Value') ;
set(handles.uipanel1,'UserData',data);


% --- Executes on button press in makeharness.
function makeharness_Callback(hObject, eventdata, handles)
% hObject    handle to makeharness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of makeharness
data = get(handles.uipanel1,'UserData');
data.mkharness =   get(hObject,'Value') ;
set(handles.uipanel1,'UserData',data);

% --- Executes on button press in run.
function run_Callback(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    data = get(handles.uipanel1,'UserData');
    random_tests( data.model_full_path, data.nb_steps, data.min, data.max, data.export2ws, data.mkharness )
catch  me
    display_msg(me.message, MsgType.ERROR, 'random_test_gui', '');
    display_msg(me.getReport(), MsgType.DEBUG, 'random_test_gui', '');
end
close(handles.figure1)


function min_Callback(hObject, eventdata, handles)
% hObject    handle to min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of min as text
%        str2double(get(hObject,'String')) returns contents of min as a double
data = get(handles.uipanel1,'UserData');
data.min =   str2num(get(hObject,'String')) ;
set(handles.uipanel1,'UserData',data);

% --- Executes during object creation, after setting all properties.
function min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && strcmp(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function max_Callback(hObject, eventdata, handles)
% hObject    handle to max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of max as text
%        str2double(get(hObject,'String')) returns contents of max as a double
data = get(handles.uipanel1,'UserData');
data.max =   str2num(get(hObject,'String')) ;
set(handles.uipanel1,'UserData',data);

% --- Executes during object creation, after setting all properties.
function max_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && strcmp(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function max_nb_test_Callback(hObject, eventdata, handles)
% hObject    handle to max_nb_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of max_nb_test as text
%        str2double(get(hObject,'String')) returns contents of max_nb_test as a double


% --- Executes during object creation, after setting all properties.
function max_nb_test_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_nb_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && strcmp(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function coverage_percentage_Callback(hObject, eventdata, handles)
% hObject    handle to coverage_percentage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of coverage_percentage as text
%        str2double(get(hObject,'String')) returns contents of coverage_percentage as a double


% --- Executes during object creation, after setting all properties.
function coverage_percentage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coverage_percentage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && strcmp(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
