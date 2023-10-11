classdef importLusReqFig_App < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        figure1                         matlab.ui.Figure
        CreateanewSimulinkfileCheckBox  matlab.ui.control.CheckBox
        importReqButton                 matlab.ui.control.Button
        importTracButton                matlab.ui.control.Button
        importLusButton                 matlab.ui.control.Button
        traceability_edit               matlab.ui.control.EditField
        lus_edit1                       matlab.ui.control.EditField
        text3                           matlab.ui.control.Label
        text2                           matlab.ui.control.Label
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function importLusReqFig_OpeningFcn(app, varargin)
            % --- Executes just before importLusReqFig is made visible.
            
            % Ensure that the app appears on screen when run
            movegui(app.figure1, 'onscreen');
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app); %#ok<ASGLU>
            
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
                'createNewFile',true);
            set(handles.figure1, 'UserData', data);
            % Update handles structure
            guidata(hObject, handles);
        end

        % Button pushed function: importLusButton
        function importLusButton_Callback(app, event)
            % --- Executes on button press in importLusButton.
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
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
        end

        % Button pushed function: importReqButton
        function importReqButton_Callback(app, event)
            % --- Executes on button press in importReqButton.
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to importReqButton (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            try
                data = get(handles.figure1,'UserData');
                importLusReq(data.gcs, data.lusPath, data.mappingPath, data.createNewFile);
            catch me
                display_msg(me.message, MsgType.ERROR, 'importLusReqFig', '');
                display_msg(me.getReport(), MsgType.DEBUG, 'importLusReqFig', '');
            end
            close(handles.figure1)
        end

        % Button pushed function: importTracButton
        function importTracButton_Callback(app, event)
            % --- Executes on button press in importTracButton.
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
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
        end

        % Value changed function: lus_edit1
        function lus_edit1_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to lus_edit1 (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hints: get(hObject,'String') returns contents of lus_edit1 as text
            %        str2double(get(hObject,'String')) returns contents of lus_edit1 as a double
            data = get(handles.figure1,'UserData');
            data.lusPath = get(hObject,'String');
            set(handles.figure1,'UserData',data);
        end

        % Value changed function: traceability_edit
        function traceability_edit_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to traceability_edit (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hints: get(hObject,'String') returns contents of traceability_edit as text
            %        str2double(get(hObject,'String')) returns contents of traceability_edit as a double
            data = get(handles.figure1,'UserData');
            data.mappingPath = get(hObject,'String');
            set(handles.figure1,'UserData',data);
        end

        % Value changed function: CreateanewSimulinkfileCheckBox
        function CreateanewSimulinkfileCheckBoxValueChanged(app, event)
            [~, ~, handles] = convertToGUIDECallbackArguments(app, event);
            data = get(handles.figure1,'UserData');
            data.createNewFile = app.CreateanewSimulinkfileCheckBox.Value;
            set(handles.figure1,'UserData',data);            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create figure1 and hide until all components are created
            app.figure1 = uifigure('Visible', 'off');
            app.figure1.Position = [1268 1601 607 201];
            app.figure1.Name = 'importLusReqFig';
            app.figure1.HandleVisibility = 'callback';
            app.figure1.Tag = 'figure1';

            % Create text2
            app.text2 = uilabel(app.figure1);
            app.text2.Tag = 'text2';
            app.text2.HorizontalAlignment = 'center';
            app.text2.VerticalAlignment = 'top';
            app.text2.WordWrap = 'on';
            app.text2.FontSize = 13.3333333333333;
            app.text2.Position = [10 146.856277056277 90 28.6476190476191];
            app.text2.Text = 'Lustre File:';

            % Create text3
            app.text3 = uilabel(app.figure1);
            app.text3.Tag = 'text3';
            app.text3.HorizontalAlignment = 'center';
            app.text3.VerticalAlignment = 'top';
            app.text3.WordWrap = 'on';
            app.text3.FontSize = 13.3333333333333;
            app.text3.Position = [11 90 90 36];
            app.text3.Text = 'Traceability File:';

            % Create lus_edit1
            app.lus_edit1 = uieditfield(app.figure1, 'text');
            app.lus_edit1.ValueChangedFcn = createCallbackFcn(app, @lus_edit1_Callback, true);
            app.lus_edit1.Tag = 'lus_edit1';
            app.lus_edit1.HorizontalAlignment = 'center';
            app.lus_edit1.FontSize = 13.3333333333333;
            app.lus_edit1.Position = [100 146.856277056277 401 35.1584415584416];
            app.lus_edit1.Value = 'Lustre File Path';

            % Create traceability_edit
            app.traceability_edit = uieditfield(app.figure1, 'text');
            app.traceability_edit.ValueChangedFcn = createCallbackFcn(app, @traceability_edit_Callback, true);
            app.traceability_edit.Tag = 'traceability_edit';
            app.traceability_edit.HorizontalAlignment = 'center';
            app.traceability_edit.FontSize = 13.3333333333333;
            app.traceability_edit.Position = [100 93.4813852813853 401 35.1584415584415];
            app.traceability_edit.Value = 'Traceability File Path';

            % Create importLusButton
            app.importLusButton = uibutton(app.figure1, 'push');
            app.importLusButton.ButtonPushedFcn = createCallbackFcn(app, @importLusButton_Callback, true);
            app.importLusButton.Tag = 'importLusButton';
            app.importLusButton.FontSize = 13.3333333333333;
            app.importLusButton.Position = [517 146.856277056277 70 27.3454545454545];
            app.importLusButton.Text = 'Load File';

            % Create importTracButton
            app.importTracButton = uibutton(app.figure1, 'push');
            app.importTracButton.ButtonPushedFcn = createCallbackFcn(app, @importTracButton_Callback, true);
            app.importTracButton.Tag = 'importTracButton';
            app.importTracButton.FontSize = 13.3333333333333;
            app.importTracButton.Position = [517 94.5480519480519 70 27.3454545454545];
            app.importTracButton.Text = 'Load File';

            % Create importReqButton
            app.importReqButton = uibutton(app.figure1, 'push');
            app.importReqButton.ButtonPushedFcn = createCallbackFcn(app, @importReqButton_Callback, true);
            app.importReqButton.Tag = 'importReqButton';
            app.importReqButton.FontSize = 13.3333333333333;
            app.importReqButton.Position = [454 9 134 29.9497835497836];
            app.importReqButton.Text = 'Import Requirement';

            % Create CreateanewSimulinkfileCheckBox
            app.CreateanewSimulinkfileCheckBox = uicheckbox(app.figure1);
            app.CreateanewSimulinkfileCheckBox.ValueChangedFcn = createCallbackFcn(app, @CreateanewSimulinkfileCheckBoxValueChanged, true);
            app.CreateanewSimulinkfileCheckBox.Text = 'Create a new Simulink file';
            app.CreateanewSimulinkfileCheckBox.Position = [100 52 161 22];
            app.CreateanewSimulinkfileCheckBox.Value = true;

            % Show the figure after all components are created
            app.figure1.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = importLusReqFig_App(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.figure1)

                % Execute the startup function
                runStartupFcn(app, @(app)importLusReqFig_OpeningFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.figure1)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.figure1)
        end
    end
end