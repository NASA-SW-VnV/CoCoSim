classdef randomTestGui_App_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        figure1      matlab.ui.Figure
        uipanel1     matlab.ui.container.Panel
        text6        matlab.ui.control.Label
        text5        matlab.ui.control.Label
        max          matlab.ui.control.EditField
        text4        matlab.ui.control.Label
        min          matlab.ui.control.EditField
        text3        matlab.ui.control.Label
        run          matlab.ui.control.Button
        makeharness  matlab.ui.control.CheckBox
        save2ws      matlab.ui.control.CheckBox
        text2        matlab.ui.control.Label
        nb_steps     matlab.ui.control.EditField
    end

    
    methods (Access = private)
        function coverage_percentage_CreateFcn(app, hObject, eventdata, handles)
            % --- Executes during object creation, after setting all properties.
            
            % hObject    handle to coverage_percentage (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    empty - handles not created until after all CreateFcns called
            
            % Hint: edit controls usually have a white background on Windows.
            %       See ISPC and COMPUTER.
            if ispc && strcmp(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
                set(hObject,'BackgroundColor','white');
            end
        end
        
        function max_nb_test_CreateFcn(app, hObject, eventdata, handles)
            % --- Executes during object creation, after setting all properties.
            
            % hObject    handle to max_nb_test (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    empty - handles not created until after all CreateFcns called
            
            % Hint: edit controls usually have a white background on Windows.
            %       See ISPC and COMPUTER.
            if ispc && strcmp(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
                set(hObject,'BackgroundColor','white');
            end
        end
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function randomTestGui_OpeningFcn(app, varargin)
            % --- Executes just before randomTestGui is made visible.
            
            % Ensure that the app appears on screen when run
            movegui(app.figure1, 'onscreen');
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app); %#ok<ASGLU>
            
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

        % Value changed function: max
        function max_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to max (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hints: get(hObject,'String') returns contents of max as text
            %        str2double(get(hObject,'String')) returns contents of max as a double
            data = get(handles.uipanel1,'UserData');
            data.max =   str2num(get(hObject,'String')) ;
            set(handles.uipanel1,'UserData',data);
        end

        % Value changed function: min
        function min_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to min (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hints: get(hObject,'String') returns contents of min as text
            %        str2double(get(hObject,'String')) returns contents of min as a double
            data = get(handles.uipanel1,'UserData');
            data.min =   str2num(get(hObject,'String')) ;
            set(handles.uipanel1,'UserData',data);
        end

        % Value changed function: nb_steps
        function nb_steps_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to nb_steps (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hints: get(hObject,'String') returns contents of nb_steps as text
            %        str2double(get(hObject,'String')) returns contents of nb_steps as a double
            data = get(handles.uipanel1,'UserData');
            data.nb_steps =  str2double(get(hObject,'String')) ;
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
                random_tests( data.model_full_path, data.nb_steps, data.min, data.max, data.export2ws, data.mkharness )
            catch  me
                display_msg(me.message, MsgType.ERROR, 'random_test_gui', '');
                display_msg(me.getReport(), MsgType.DEBUG, 'random_test_gui', '');
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
            app.figure1.Position = [951 849 698 318];
            app.figure1.Name = 'randomTestGui';
            app.figure1.HandleVisibility = 'callback';
            app.figure1.Tag = 'figure1';

            % Create uipanel1
            app.uipanel1 = uipanel(app.figure1);
            app.uipanel1.Title = 'CoCoSim';
            app.uipanel1.Tag = 'uipanel1';
            app.uipanel1.FontSize = 13.3333333333333;
            app.uipanel1.Position = [0 3 700 315];

            % Create nb_steps
            app.nb_steps = uieditfield(app.uipanel1, 'text');
            app.nb_steps.ValueChangedFcn = createCallbackFcn(app, @nb_steps_Callback, true);
            app.nb_steps.Tag = 'nb_steps';
            app.nb_steps.HorizontalAlignment = 'center';
            app.nb_steps.FontSize = 18.6666666666667;
            app.nb_steps.Position = [188.785413744741 237.484713646458 205.482468443198 25.5915189541325];
            app.nb_steps.Value = '100';

            % Create text2
            app.text2 = uilabel(app.uipanel1);
            app.text2.Tag = 'text2';
            app.text2.HorizontalAlignment = 'center';
            app.text2.VerticalAlignment = 'top';
            app.text2.WordWrap = 'on';
            app.text2.FontSize = 18.6666666666667;
            app.text2.Position = [6 238 167 25];
            app.text2.Text = 'Number of steps';

            % Create save2ws
            app.save2ws = uicheckbox(app.uipanel1);
            app.save2ws.ValueChangedFcn = createCallbackFcn(app, @save2ws_Callback, true);
            app.save2ws.Tag = 'save2ws';
            app.save2ws.Text = 'Save Test cases to Workspace';
            app.save2ws.FontSize = 18.6666666666667;
            app.save2ws.Position = [8 93.1992857142857 686 27.5538095238095];
            app.save2ws.Value = true;

            % Create makeharness
            app.makeharness = uicheckbox(app.uipanel1);
            app.makeharness.ValueChangedFcn = createCallbackFcn(app, @makeharness_Callback, true);
            app.makeharness.Tag = 'makeharness';
            app.makeharness.Text = 'Generate Harness model (test cases in Signal builder)';
            app.makeharness.FontSize = 18.6666666666667;
            app.makeharness.Position = [7.56503642039542 62.7085192853309 685.681581685744 27.0316080055211];

            % Create run
            app.run = uibutton(app.uipanel1, 'push');
            app.run.ButtonPushedFcn = createCallbackFcn(app, @run_Callback, true);
            app.run.Tag = 'run';
            app.run.FontSize = 13.3333333333333;
            app.run.Position = [13.4006243496358 7.89442527413541 96.2872008324662 48.8070700099685];
            app.run.Text = 'Run';

            % Create text3
            app.text3 = uilabel(app.uipanel1);
            app.text3.Tag = 'text3';
            app.text3.HorizontalAlignment = 'center';
            app.text3.VerticalAlignment = 'top';
            app.text3.WordWrap = 'on';
            app.text3.FontSize = 18.6666666666667;
            app.text3.Position = [6 161 167 24];
            app.text3.Text = 'Min';

            % Create min
            app.min = uieditfield(app.uipanel1, 'text');
            app.min.ValueChangedFcn = createCallbackFcn(app, @min_Callback, true);
            app.min.Tag = 'min';
            app.min.HorizontalAlignment = 'center';
            app.min.FontSize = 18.6666666666667;
            app.min.Position = [186.819074333801 159.539130981018 207.448807854137 25.5915189541324];
            app.min.Value = '-100';

            % Create text4
            app.text4 = uilabel(app.uipanel1);
            app.text4.Tag = 'text4';
            app.text4.HorizontalAlignment = 'center';
            app.text4.VerticalAlignment = 'top';
            app.text4.WordWrap = 'on';
            app.text4.FontSize = 18.6666666666667;
            app.text4.Position = [8 130 167 27];
            app.text4.Text = 'Max';

            % Create max
            app.max = uieditfield(app.uipanel1, 'text');
            app.max.ValueChangedFcn = createCallbackFcn(app, @max_Callback, true);
            app.max.Tag = 'max';
            app.max.HorizontalAlignment = 'center';
            app.max.FontSize = 18.6666666666667;
            app.max.Position = [186.819074333801 130.108884183766 207.448807854137 25.5915189541324];
            app.max.Value = '100';

            % Create text5
            app.text5 = uilabel(app.uipanel1);
            app.text5.Tag = 'text5';
            app.text5.VerticalAlignment = 'top';
            app.text5.WordWrap = 'on';
            app.text5.FontSize = 18.6666666666667;
            app.text5.Position = [5.90896358543417 195.695353913651 622.456582633053 22.9585453694285];
            app.text5.Text = 'e.g, Min = -100, Min = [-0.3, 15, 10] if you choose to specify a different Min value for each input ';

            % Create text6
            app.text6 = uilabel(app.uipanel1);
            app.text6.Tag = 'text6';
            app.text6.VerticalAlignment = 'top';
            app.text6.WordWrap = 'on';
            app.text6.FontSize = 18.6666666666667;
            app.text6.Position = [7.81409477521264 268.319533527697 563.014580801944 21.6277939747328];
            app.text6.Text = '(Number of steps)  * (Simulation step)  =  (Stop time)';

            % Show the figure after all components are created
            app.figure1.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = randomTestGui_App_exported(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.figure1)

                % Execute the startup function
                runStartupFcn(app, @(app)randomTestGui_OpeningFcn(app, varargin{:}))
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