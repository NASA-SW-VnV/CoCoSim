function varargout = random_test_gui(varargin)
% RANDOM_TEST_GUI MATLAB code for random_test_gui.fig
%      RANDOM_TEST_GUI, by itself, creates a new RANDOM_TEST_GUI or raises the existing
%      singleton*.
%
%      H = RANDOM_TEST_GUI returns the handle to a new RANDOM_TEST_GUI or the handle to
%      the existing singleton*.
%
%      RANDOM_TEST_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RANDOM_TEST_GUI.M with the given input arguments.
%
%      RANDOM_TEST_GUI('Property','Value',...) creates a new RANDOM_TEST_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before random_test_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to random_test_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help random_test_gui

% Last Modified by GUIDE v2.5 17-Jan-2018 15:04:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @random_test_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @random_test_gui_OutputFcn, ...
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
end
% --- Executes just before random_test_gui is made visible.
function random_test_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to random_test_gui (see VARARGIN)

% Choose default command line output for random_test_gui
handles.output = hObject;

if strcmp(varargin{1}, 'model_full_path')
    model_full_path = varargin{2};
else
    display_msg('USE: random_test_gui(''model_full_path'',''path_to_model'');',...
        MsgType.ERROR, 'random_test_gui', '');
    errordlg('USE: random_test_gui(''model_full_path'',''path_to_model'');');
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

% UIWAIT makes random_test_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = random_test_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
data = get(handles.uipanel1,'UserData');
data.nb_steps =  str2double(get(hObject,'String')) ;
set(handles.uipanel1,'UserData',data);

end

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
data = get(handles.uipanel1,'UserData');
data.export2ws =   get(hObject,'Value') ;
set(handles.uipanel1,'UserData',data);

end

% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2
data = get(handles.uipanel1,'UserData');
data.mkharness =   get(hObject,'Value') ;
set(handles.uipanel1,'UserData',data);
end
% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
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
end



% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function edit1_DeleteFcn(hObject, eventdata, handles)
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
data = get(handles.uipanel1,'UserData');
data.min =   str2num(get(hObject,'String')) ;
set(handles.uipanel1,'UserData',data);
end

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double
data = get(handles.uipanel1,'UserData');
data.max =   str2num(get(hObject,'String')) ;
set(handles.uipanel1,'UserData',data);
end

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
