function varargout = mutation_test_gui(varargin)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MUTATION_TEST_GUI MATLAB code for mutation_test_gui.fig
    %      MUTATION_TEST_GUI, by itself, creates a new MUTATION_TEST_GUI or raises the existing
    %      singleton*.
    %
    %      H = MUTATION_TEST_GUI returns the handle to a new MUTATION_TEST_GUI or the handle to
    %      the existing singleton*.
    %
    %      MUTATION_TEST_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in MUTATION_TEST_GUI.M with the given input arguments.
    %
    %      MUTATION_TEST_GUI('Property','Value',...) creates a new MUTATION_TEST_GUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before mutation_test_gui_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to mutation_test_gui_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help mutation_test_gui

    % Last Modified by GUIDE v2.5 17-Jan-2018 16:42:06

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @mutation_test_gui_OpeningFcn, ...
        'gui_OutputFcn',  @mutation_test_gui_OutputFcn, ...
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
% --- Executes just before mutation_test_gui is made visible.
function mutation_test_gui_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to mutation_test_gui (see VARARGIN)

    % Choose default command line output for mutation_test_gui
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
        'max_nb_test', 100,...
        'min_coverage', 95, ...
        'export2ws', 1, ...
        'mkharness', 0);
    set(handles.uipanel1, 'UserData', data);
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes mutation_test_gui wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = mutation_test_gui_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end

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

end

function nb_steps_DeleteFcn(hObject, eventdata, handles)
end

function nb_steps_Callback(hObject, eventdata, handles)
    % hObject    handle to nb_steps (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of nb_steps as text
    %        str2double(get(hObject,'String')) returns contents of nb_steps as a double
    data = get(handles.uipanel1,'UserData');
    data.nb_steps =  str2double(get(hObject,'String')) ;
    set(handles.uipanel1,'UserData',data);

end

function min_Callback(hObject, eventdata, handles)
    % hObject    handle to min (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of min as text
    %        str2double(get(hObject,'String')) returns contents of min as a double
    data = get(handles.uipanel1,'UserData');
    data.min =   str2num(get(hObject,'String')) ;
    set(handles.uipanel1,'UserData',data);
end

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
end

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
end

function max_nb_test_Callback(hObject, eventdata, handles)
    % hObject    handle to max_nb_test (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of max_nb_test as text
    %        str2double(get(hObject,'String')) returns contents of max_nb_test as a double
    data = get(handles.uipanel1,'UserData');
    data.max_nb_test =   str2num(get(hObject,'String')) ;
    set(handles.uipanel1,'UserData',data);
end

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
end


function coverage_percentage_Callback(hObject, eventdata, handles)
    % hObject    handle to coverage_percentage (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of coverage_percentage as text
    %        str2double(get(hObject,'String')) returns contents of coverage_percentage as a double
    data = get(handles.uipanel1,'UserData');
    data.min_coverage =   str2num(get(hObject,'String')) ;
    set(handles.uipanel1,'UserData',data);
end

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
        mutation_tests( data.model_full_path, ...
            data.export2ws, ...
            data.mkharness,...
            data.nb_steps,...
            data.min,...
            data.max,...
            data.max_nb_test, ...
            data.min_coverage )
    catch me
        display_msg(me.message, MsgType.ERROR, 'mutation_test_gui', '');
        display_msg(me.getReport(), MsgType.DEBUG, 'mutation_test_gui', '');
    end
    try close(handles.figure1), catch,end
end
