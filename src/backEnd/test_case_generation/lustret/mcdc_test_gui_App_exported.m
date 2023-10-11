classdef mcdc_test_gui_App_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        figure1      matlab.ui.Figure
        uipanel1     matlab.ui.container.Panel
        run          matlab.ui.control.Button
        makeharness  matlab.ui.control.CheckBox
        save2ws      matlab.ui.control.CheckBox
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function mcdc_test_gui_OpeningFcn(app, varargin)
            % --- Executes just before mcdc_test_gui is made visible.
            
            % Ensure that the app appears on screen when run
            movegui(app.figure1, 'onscreen');
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app); %#ok<ASGLU>
            
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

        % Value changed function: makeharness
        function makeharness_Callback(app, event)
            % --- Executes on button press in makeharness.
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to makeharness (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hint: get(hObject,'Value') returns toggle state of makeharness
            data = get(handles.uipanel1,'UserData');
            data.mkharness =   get(hObject,'Value') ;
            set(handles.uipanel1,'UserData',data);
        end

        % Button pushed function: run
        function run_Callback(app, event)
            % --- Executes on button press in run.
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
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

        % Value changed function: save2ws
        function save2ws_Callback(app, event)
            % --- Executes on button press in save2ws.
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to save2ws (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hint: get(hObject,'Value') returns toggle state of save2ws
            data = get(handles.uipanel1,'UserData');
            data.export2ws =   get(hObject,'Value') ;
            set(handles.uipanel1,'UserData',data);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create figure1 and hide until all components are created
            app.figure1 = uifigure('Visible', 'off');
            app.figure1.Position = [951 983 908 183];
            app.figure1.Name = 'mcdc_test_gui';
            app.figure1.HandleVisibility = 'callback';
            app.figure1.Tag = 'figure1';

            % Create uipanel1
            app.uipanel1 = uipanel(app.figure1);
            app.uipanel1.Title = 'CoCoSim';
            app.uipanel1.Tag = 'uipanel1';
            app.uipanel1.FontSize = 13.3333333333333;
            app.uipanel1.Position = [0 -5 906 188];

            % Create save2ws
            app.save2ws = uicheckbox(app.uipanel1);
            app.save2ws.ValueChangedFcn = createCallbackFcn(app, @save2ws_Callback, true);
            app.save2ws.Tag = 'save2ws';
            app.save2ws.Text = 'Save Test cases to Workspace';
            app.save2ws.FontSize = 18.6666666666667;
            app.save2ws.Position = [6.83333333333333 129.773595199127 544.833333333333 32.494271685761];
            app.save2ws.Value = true;

            % Create makeharness
            app.makeharness = uicheckbox(app.uipanel1);
            app.makeharness.ValueChangedFcn = createCallbackFcn(app, @makeharness_Callback, true);
            app.makeharness.Tag = 'makeharness';
            app.makeharness.Text = 'Add MC-DC conditions to the Simulink model';
            app.makeharness.FontSize = 18.6666666666667;
            app.makeharness.Position = [8 91.2618657937807 751.333333333333 32.494271685761];

            % Create run
            app.run = uibutton(app.uipanel1, 'push');
            app.run.ButtonPushedFcn = createCallbackFcn(app, @run_Callback, true);
            app.run.Tag = 'run';
            app.run.FontSize = 13.3333333333333;
            app.run.Position = [17.3333333333333 16.5828710296796 131.833333333333 59.5181272628081];
            app.run.Text = 'Run';

            % Show the figure after all components are created
            app.figure1.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = mcdc_test_gui_App_exported(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.figure1)

                % Execute the startup function
                runStartupFcn(app, @(app)mcdc_test_gui_OpeningFcn(app, varargin{:}))
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