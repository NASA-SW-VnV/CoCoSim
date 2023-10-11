classdef mutation_test_gui_App_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        figure1              matlab.ui.Figure
        uipanel1             matlab.ui.container.Panel
        coverage_percentage  matlab.ui.control.EditField
        max_nb_test          matlab.ui.control.EditField
        text9                matlab.ui.control.Label
        text8                matlab.ui.control.Label
        text7                matlab.ui.control.Label
        text6                matlab.ui.control.Label
        text5                matlab.ui.control.Label
        max                  matlab.ui.control.EditField
        text4                matlab.ui.control.Label
        min                  matlab.ui.control.EditField
        text3                matlab.ui.control.Label
        run                  matlab.ui.control.Button
        makeharness          matlab.ui.control.CheckBox
        save2ws              matlab.ui.control.CheckBox
        text2                matlab.ui.control.Label
        nb_steps             matlab.ui.control.EditField
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function mutation_test_gui_OpeningFcn(app, varargin)
            % --- Executes just before mutation_test_gui is made visible.
            
            % Ensure that the app appears on screen when run
            movegui(app.figure1, 'onscreen');
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app); %#ok<ASGLU>
            
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

        % Value changed function: coverage_percentage
        function coverage_percentage_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
                % hObject    handle to coverage_percentage (see GCBO)
                % eventdata  reserved - to be defined in a future version of MATLAB
                % handles    structure with handles and user data (see GUIDATA)
            
                % Hints: get(hObject,'String') returns contents of coverage_percentage as text
                %        str2double(get(hObject,'String')) returns contents of coverage_percentage as a double
                data = get(handles.uipanel1,'UserData');
                data.min_coverage =   str2num(get(hObject,'String')) ;
                set(handles.uipanel1,'UserData',data);
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

        % Value changed function: max_nb_test
        function max_nb_test_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
                % hObject    handle to max_nb_test (see GCBO)
                % eventdata  reserved - to be defined in a future version of MATLAB
                % handles    structure with handles and user data (see GUIDATA)
            
                % Hints: get(hObject,'String') returns contents of max_nb_test as text
                %        str2double(get(hObject,'String')) returns contents of max_nb_test as a double
                data = get(handles.uipanel1,'UserData');
                data.max_nb_test =   str2num(get(hObject,'String')) ;
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
            app.figure1.Position = [951 492 961 674];
            app.figure1.Name = 'mutation_test_gui';
            app.figure1.HandleVisibility = 'callback';
            app.figure1.Tag = 'figure1';

            % Create uipanel1
            app.uipanel1 = uipanel(app.figure1);
            app.uipanel1.Title = 'CoCoSim';
            app.uipanel1.Tag = 'uipanel1';
            app.uipanel1.FontSize = 13.3333333333333;
            app.uipanel1.Position = [0 -4 965 678];

            % Create nb_steps
            app.nb_steps = uieditfield(app.uipanel1, 'text');
            app.nb_steps.ValueChangedFcn = createCallbackFcn(app, @nb_steps_Callback, true);
            app.nb_steps.Tag = 'nb_steps';
            app.nb_steps.HorizontalAlignment = 'center';
            app.nb_steps.FontSize = 18.6666666666667;
            app.nb_steps.Position = [258.390135577373 575.723364631024 281.646797568957 36.2225498564445];
            app.nb_steps.Value = '100';

            % Create text2
            app.text2 = uilabel(app.uipanel1);
            app.text2.Tag = 'text2';
            app.text2.HorizontalAlignment = 'center';
            app.text2.VerticalAlignment = 'top';
            app.text2.WordWrap = 'on';
            app.text2.FontSize = 18.6666666666667;
            app.text2.Position = [7.20029252812884 580.281734834652 228.359491778774 24.9230376224651];
            app.text2.Text = 'Number of steps';

            % Create save2ws
            app.save2ws = uicheckbox(app.uipanel1);
            app.save2ws.ValueChangedFcn = createCallbackFcn(app, @save2ws_Callback, true);
            app.save2ws.Tag = 'save2ws';
            app.save2ws.Text = 'Save Test cases to Workspace';
            app.save2ws.FontSize = 18.6666666666667;
            app.save2ws.Position = [11.5072904009721 146.714285714286 939.818752531389 37.9591836734694];
            app.save2ws.Value = true;

            % Create makeharness
            app.makeharness = uicheckbox(app.uipanel1);
            app.makeharness.ValueChangedFcn = createCallbackFcn(app, @makeharness_Callback, true);
            app.makeharness.Tag = 'makeharness';
            app.makeharness.Text = 'Generate Harness model (test cases in Signal builder)';
            app.makeharness.FontSize = 18.6666666666667;
            app.makeharness.Position = [11.5072904009721 107.530612244898 939.818752531389 37.9591836734694];

            % Create run
            app.run = uibutton(app.uipanel1, 'push');
            app.run.ButtonPushedFcn = createCallbackFcn(app, @run_Callback, true);
            app.run.Tag = 'run';
            app.run.FontSize = 13.3333333333333;
            app.run.Position = [22.0145808019441 24.265306122449 131.92486836776 68.5714285714286];
            app.run.Text = 'Run';

            % Create text3
            app.text3 = uilabel(app.uipanel1);
            app.text3.Tag = 'text3';
            app.text3.HorizontalAlignment = 'center';
            app.text3.VerticalAlignment = 'top';
            app.text3.WordWrap = 'on';
            app.text3.FontSize = 18.6666666666667;
            app.text3.Position = [11.765639589169 473.246449910763 228.769841269841 25.2745163581665];
            app.text3.Text = 'Min';

            % Create min
            app.min = uieditfield(app.uipanel1, 'text');
            app.min.ValueChangedFcn = createCallbackFcn(app, @min_Callback, true);
            app.min.Tag = 'min';
            app.min.HorizontalAlignment = 'center';
            app.min.FontSize = 18.6666666666667;
            app.min.Position = [255.694950911641 465.3982307752 284.341982234689 36.2225498564444];
            app.min.Value = '-100';

            % Create text4
            app.text4 = uilabel(app.uipanel1);
            app.text4.Tag = 'text4';
            app.text4.HorizontalAlignment = 'center';
            app.text4.VerticalAlignment = 'top';
            app.text4.WordWrap = 'on';
            app.text4.FontSize = 18.6666666666667;
            app.text4.Position = [13.1113445378151 426.308062388453 228.769841269841 25.2745163581665];
            app.text4.Text = 'Max';

            % Create max
            app.max = uieditfield(app.uipanel1, 'text');
            app.max.ValueChangedFcn = createCallbackFcn(app, @max_Callback, true);
            app.max.Tag = 'max';
            app.max.HorizontalAlignment = 'center';
            app.max.FontSize = 18.6666666666667;
            app.max.Position = [255.694950911641 423.742298440289 284.341982234689 36.2225498564444];
            app.max.Value = '100';

            % Create text5
            app.text5 = uilabel(app.uipanel1);
            app.text5.Tag = 'text5';
            app.text5.VerticalAlignment = 'top';
            app.text5.WordWrap = 'on';
            app.text5.FontSize = 18.6666666666667;
            app.text5.Position = [7.72852474323063 516.574192239048 853.176937441643 32.4958067462142];
            app.text5.Text = 'e.g, Min = -100, Min = [-0.3, 15, 10] if you choose to specify a different Min value for each input ';

            % Create text6
            app.text6 = uilabel(app.uipanel1);
            app.text6.Tag = 'text6';
            app.text6.VerticalAlignment = 'top';
            app.text6.WordWrap = 'on';
            app.text6.FontSize = 18.6666666666667;
            app.text6.Position = [10.3398136897529 619.367346938776 771.702106115836 30.6122448979592];
            app.text6.Text = '(Number of steps)  * (Simulation step)  =  (Stop time)';

            % Create text7
            app.text7 = uilabel(app.uipanel1);
            app.text7.Tag = 'text7';
            app.text7.VerticalAlignment = 'top';
            app.text7.WordWrap = 'on';
            app.text7.FontSize = 18.6666666666667;
            app.text7.Position = [6.83738355609558 375.69387755102 853.425475901175 33.0612244897959];
            app.text7.Text = 'Maximum number of tests should be generated. (Test coverage can be met before this number)';

            % Create text8
            app.text8 = uilabel(app.uipanel1);
            app.text8.Tag = 'text8';
            app.text8.HorizontalAlignment = 'center';
            app.text8.VerticalAlignment = 'top';
            app.text8.WordWrap = 'on';
            app.text8.FontSize = 18.6666666666667;
            app.text8.Position = [8.0048602673147 333.276504049997 228.769841269841 25.2745163581665];
            app.text8.Text = 'Maximum number of tests.';

            % Create text9
            app.text9 = uilabel(app.uipanel1);
            app.text9.Tag = 'text9';
            app.text9.HorizontalAlignment = 'center';
            app.text9.VerticalAlignment = 'top';
            app.text9.WordWrap = 'on';
            app.text9.FontSize = 18.6666666666667;
            app.text9.Position = [6.83738355609558 275.285714285714 246.337586067234 44.0816326530612];
            app.text9.Text = 'Minimum coverage percentage (%)';

            % Create max_nb_test
            app.max_nb_test = uieditfield(app.uipanel1, 'text');
            app.max_nb_test.ValueChangedFcn = createCallbackFcn(app, @max_nb_test_Callback, true);
            app.max_nb_test.Tag = 'max_nb_test';
            app.max_nb_test.HorizontalAlignment = 'center';
            app.max_nb_test.FontSize = 18.6666666666667;
            app.max_nb_test.Position = [257.844876468206 329.675409327229 284.341982234689 36.2225498564444];
            app.max_nb_test.Value = '100';

            % Create coverage_percentage
            app.coverage_percentage = uieditfield(app.uipanel1, 'text');
            app.coverage_percentage.ValueChangedFcn = createCallbackFcn(app, @coverage_percentage_Callback, true);
            app.coverage_percentage.Tag = 'coverage_percentage';
            app.coverage_percentage.HorizontalAlignment = 'center';
            app.coverage_percentage.FontSize = 18.6666666666667;
            app.coverage_percentage.Position = [259.012353179425 276.510204081633 284.864317537464 47.7551020408163];
            app.coverage_percentage.Value = '95';

            % Show the figure after all components are created
            app.figure1.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = mutation_test_gui_App_exported(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.figure1)

                % Execute the startup function
                runStartupFcn(app, @(app)mutation_test_gui_OpeningFcn(app, varargin{:}))
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