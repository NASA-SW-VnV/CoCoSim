function varargout = mcdc_test_gui(varargin)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % MCDC_TEST_GUI MATLAB code for mcdc_test_gui.fig
    %      MCDC_TEST_GUI, by itself, creates a new MCDC_TEST_GUI or raises the existing
    %      singleton*.
    %
    %      H = MCDC_TEST_GUI returns the handle to a new MCDC_TEST_GUI or the handle to
    %      the existing singleton*.
    %
    %      MCDC_TEST_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in MCDC_TEST_GUI.M with the given input arguments.
    %
    %      MCDC_TEST_GUI('Property','Value',...) creates a new MCDC_TEST_GUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before mcdc_test_gui_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to mcdc_test_gui_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help mcdc_test_gui

    % Last Modified by GUIDE v2.5 18-Jan-2018 15:30:17

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @mcdc_test_gui_OpeningFcn, ...
        'gui_OutputFcn',  @mcdc_test_gui_OutputFcn, ...
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
% --- Executes just before mcdc_test_gui is made visible.
function mcdc_test_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mcdc_test_gui (see VARARGIN)

% Choose default command line output for mcdc_test_gui
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
    'export2ws', 1, ...
    'mkharness', 0);
set(handles.uipanel1, 'UserData', data);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mcdc_test_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = mcdc_test_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
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

end

% --- Executes on button press in makeharness.
function makeharness_Callback(hObject, eventdata, handles)
% hObject    handle to makeharness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of makeharness
data = get(handles.uipanel1,'UserData');
data.mkharness =   get(hObject,'Value') ;
set(handles.uipanel1,'UserData',data);
end
% --- Executes on button press in run.
function run_Callback(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    data = get(handles.uipanel1,'UserData');
    mcdc_tests( data.model_full_path,...
        data.export2ws, ...
        data.mkharness );
catch me
    display_msg(me.message, MsgType.ERROR, 'mutation_test_gui', '');
    display_msg(me.getReport(), MsgType.DEBUG, 'mutation_test_gui', '');
end
close(handles.figure1)
end
