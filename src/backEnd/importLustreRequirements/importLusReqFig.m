function varargout = importLusReqFig(varargin)
% IMPORTLUSREQFIG MATLAB code for importLusReqFig.fig
%      IMPORTLUSREQFIG, by itself, creates a new IMPORTLUSREQFIG or raises the existing
%      singleton*.
%
%      H = IMPORTLUSREQFIG returns the handle to a new IMPORTLUSREQFIG or the handle to
%      the existing singleton*.
%
%      IMPORTLUSREQFIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMPORTLUSREQFIG.M with the given input arguments.
%
%      IMPORTLUSREQFIG('Property','Value',...) creates a new IMPORTLUSREQFIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before importLusReqFig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to importLusReqFig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help importLusReqFig

% Last Modified by GUIDE v2.5 03-Apr-2019 18:33:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @importLusReqFig_OpeningFcn, ...
                   'gui_OutputFcn',  @importLusReqFig_OutputFcn, ...
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


% --- Executes just before importLusReqFig is made visible.
function importLusReqFig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to importLusReqFig (see VARARGIN)

% Choose default command line output for importLusReqFig
handles.output = hObject;

if strcmp(varargin{1}, 'gcs')
    gcs_path = varargin{2};
else
    display_msg('USE: importLusReqFig(''gcs'','' path name of the current Simulink system'');',...
        MsgType.ERROR, 'importLusReqFig', '');
    errordlg('USE: importLusReqFig(''gcs'','' path name of the current Simulink system'');');
    return;
end
data = struct('gcs', gcs_path,...
    'lusPath', '', ...
    'mappingPath', '', ...
    'createNewFile','1');
set(handles.figure1, 'UserData', data);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes importLusReqFig wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = importLusReqFig_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function lus_edit1_Callback(hObject, eventdata, handles)
% hObject    handle to lus_edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lus_edit1 as text
%        str2double(get(hObject,'String')) returns contents of lus_edit1 as a double
data = get(handles.figure1,'UserData');
data.lusPath = get(hObject,'String');
set(handles.figure1,'UserData',data);

% --- Executes during object creation, after setting all properties.
function lus_edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lus_edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && strcmp(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function traceability_edit_Callback(hObject, eventdata, handles)
% hObject    handle to traceability_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of traceability_edit as text
%        str2double(get(hObject,'String')) returns contents of traceability_edit as a double
data = get(handles.figure1,'UserData');
data.mappingPath = get(hObject,'String');
set(handles.figure1,'UserData',data);


% --- Executes during object creation, after setting all properties.
function traceability_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to traceability_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
set(hObject,'String', '');
if ispc && strcmp(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in importLusButton.
function importLusButton_Callback(hObject, eventdata, handles)
% hObject    handle to importLusButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.figure1,'UserData');
[file, p] = uigetfile({'*.lus', '*.lusi'});
if ischar(file) && ~isempty(file)
    data.lusPath = fullfile(p, file);
    handles.lus_edit1.String = fullfile(p, file);
    set(handles.figure1,'UserData',data);
end

% --- Executes on button press in importTracButton.
function importTracButton_Callback(hObject, eventdata, handles)
% hObject    handle to importTracButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.figure1,'UserData');
[file, p] = uigetfile({'*.json'});
if ischar(file) && ~isempty(file)
    data.mappingPath = fullfile(p, file);
    handles.traceability_edit.String = fullfile(p, file);
    set(handles.figure1,'UserData',data);
end



% --- Executes on button press in importReqButton.
function importReqButton_Callback(hObject, eventdata, handles)
% hObject    handle to importReqButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    data = get(handles.figure1,'UserData');
    importLusReq(data.gcs, data.lusPath, data.mappingPath, str2num(data.createNewFile));
catch me
    display_msg(me.message, MsgType.ERROR, 'importLusReqFig', '');
    display_msg(me.getReport(), MsgType.DEBUG, 'importLusReqFig', '');
end
close(handles.figure1)


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1
data = get(handles.figure1,'UserData');
data.createNewFile = get(hObject,'String');
set(handles.figure1,'UserData',data);
