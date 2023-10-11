classdef importLusTestOblFig < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        CreateanewSimulinkfileCheckBox  matlab.ui.control.CheckBox
        ButtonGroup                     matlab.ui.container.ButtonGroup
        CreateaseparateSimulinkfileperrequirementButton  matlab.ui.control.RadioButton
        CreateanewSimulinkfilecontainingallobligationsButton  matlab.ui.control.RadioButton
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
        function startupFcn(app)
            app.UIFigure.UserData = struct('gcs', gcs,...
                'lusPath', '', ...
                'mappingPath', '', ...
                'createNewFile',true, ...
                'createSeparateFiles',false);            
            
        end

        % Button pushed function: importReqButton
        function importReqButtonPushed(app, event)
            try                
                data = get(app.UIFigure,'UserData');
                if (data.createNewFile)
                    importLusReq(data.gcs, data.lusPath, data.mappingPath, data.createNewFile, data.createSeparateFiles);
                else                    
                    importLusTestObl_separately(data.gcs, data.lusPath, data.mappingPath, data.createNewFile, data.createSeparateFiles);
                end
            catch me
                display_msg(me.message, MsgType.ERROR, 'importLusTestOblFig', 'Something went wrong while importing test obligations.');
                display_msg(me.getReport(), MsgType.DEBUG, 'importLusTestOblFig', 'Something went wrong while importing test obligations.');
            end
            close(app.UIFigure)
        end

        % Button pushed function: importLusButton
        function importLusButtonPushed(app, event)
            data = get(app.UIFigure,'UserData');
            [file, p] = uigetfile({'*.lus', '*.lusi'});
            if ischar(file) && ~isempty(file)
                data.lusPath = fullfile(p, file);
                app.lus_edit1.Value = fullfile(p, file);
                set(app.UIFigure,'UserData',data);
            end
        end

        % Button pushed function: importTracButton
        function importTracButtonPushed(app, event)
            data = get(app.UIFigure,'UserData');
            [file, p] = uigetfile({'*.json'});
            if ischar(file) && ~isempty(file)
                data.mappingPath = fullfile(p, file);
                app.traceability_edit.Value = fullfile(p, file);
                set(app.UIFigure,'UserData',data);
            end
        end

        % Value changed function: CreateanewSimulinkfileCheckBox
        function CreateanewSimulinkfileCheckBoxValueChanged(app, event)
            value = app.CreateanewSimulinkfileCheckBox.Value;
            data = get(app.UIFigure,'UserData');            
            if (value)
                app.ButtonGroup.Enable = "on";
                data.createNewFile = app.CreateanewSimulinkfilecontainingallobligationsButton.Value;
                data.createSeparateFiles = app.CreateaseparateSimulinkfileperrequirementButton.Value;
                set(app.UIFigure,'UserData',data);
            else
                app.ButtonGroup.Enable = "off";
                data.createNewFile = false;
                data.createSeparateFiles = false;
                set(app.UIFigure,'UserData',data);
            end
        end

        % Selection changed function: ButtonGroup
        function ButtonGroupSelectionChanged(app, event)
            selectedButton = app.ButtonGroup.SelectedObject;
            data = get(app.UIFigure,'UserData');
            switch selectedButton.Text
                case 'Create a new Simulink file containing all obligations'
                    data.createNewFile = selectedButton.Value;
                    data.createSeparateFiles = ~selectedButton.Value;
                case 'Create a separate Simulink file per obligation (recommended for large obligation sets)'
                    data.createNewFile = ~selectedButton.Value;
                    data.createSeparateFiles = selectedButton.Value;
            end
            set(app.UIFigure,'UserData',data);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 649 259];
            app.UIFigure.Name = 'MATLAB App';

            % Create text2
            app.text2 = uilabel(app.UIFigure);
            app.text2.Tag = 'text2';
            app.text2.HorizontalAlignment = 'center';
            app.text2.VerticalAlignment = 'top';
            app.text2.WordWrap = 'on';
            app.text2.FontSize = 13.3333333333333;
            app.text2.Position = [47 204 66 17];
            app.text2.Text = 'Lustre File:';

            % Create text3
            app.text3 = uilabel(app.UIFigure);
            app.text3.Tag = 'text3';
            app.text3.HorizontalAlignment = 'center';
            app.text3.VerticalAlignment = 'top';
            app.text3.WordWrap = 'on';
            app.text3.FontSize = 13.3333333333333;
            app.text3.Position = [14 152 98 17];
            app.text3.Text = 'Traceability File:';

            % Create lus_edit1
            app.lus_edit1 = uieditfield(app.UIFigure, 'text');
            app.lus_edit1.Tag = 'lus_edit1';
            app.lus_edit1.HorizontalAlignment = 'center';
            app.lus_edit1.FontSize = 13.3333333333333;
            app.lus_edit1.Position = [125 199 401 35.1584415584416];
            app.lus_edit1.Value = 'Lustre File Path';

            % Create traceability_edit
            app.traceability_edit = uieditfield(app.UIFigure, 'text');
            app.traceability_edit.Tag = 'traceability_edit';
            app.traceability_edit.HorizontalAlignment = 'center';
            app.traceability_edit.FontSize = 13.3333333333333;
            app.traceability_edit.Position = [125 145 401 35.1584415584415];
            app.traceability_edit.Value = 'Traceability File Path';

            % Create importLusButton
            app.importLusButton = uibutton(app.UIFigure, 'push');
            app.importLusButton.ButtonPushedFcn = createCallbackFcn(app, @importLusButtonPushed, true);
            app.importLusButton.Tag = 'importLusButton';
            app.importLusButton.FontSize = 13.3333333333333;
            app.importLusButton.Position = [542 199 70 27.3454545454545];
            app.importLusButton.Text = 'Load File';

            % Create importTracButton
            app.importTracButton = uibutton(app.UIFigure, 'push');
            app.importTracButton.ButtonPushedFcn = createCallbackFcn(app, @importTracButtonPushed, true);
            app.importTracButton.Tag = 'importTracButton';
            app.importTracButton.FontSize = 13.3333333333333;
            app.importTracButton.Position = [543 149 70 27.3454545454546];
            app.importTracButton.Text = 'Load File';

            % Create importReqButton
            app.importReqButton = uibutton(app.UIFigure, 'push');
            app.importReqButton.ButtonPushedFcn = createCallbackFcn(app, @importReqButtonPushed, true);
            app.importReqButton.Tag = 'importReqButton';
            app.importReqButton.FontSize = 13.3333333333333;
            app.importReqButton.Position = [468 10 151 30];
            app.importReqButton.Text = 'Import Test Obligations';

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.UIFigure);
            app.ButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroupSelectionChanged, true);
            app.ButtonGroup.BorderType = 'none';
            app.ButtonGroup.Position = [125 56 497 53];

            % Create CreateanewSimulinkfilecontainingallobligationsButton
            app.CreateanewSimulinkfilecontainingallobligationsButton = uiradiobutton(app.ButtonGroup);
            app.CreateanewSimulinkfilecontainingallobligationsButton.Text = 'Create a new Simulink file containing all obligations';
            app.CreateanewSimulinkfilecontainingallobligationsButton.Position = [11 28 299 22];
            app.CreateanewSimulinkfilecontainingallobligationsButton.Value = true;

            % Create CreateaseparateSimulinkfileperrequirementButton
            app.CreateaseparateSimulinkfileperrequirementButton = uiradiobutton(app.ButtonGroup);
            app.CreateaseparateSimulinkfileperrequirementButton.Text = 'Create a separate Simulink file per obligation (recommended for large obligation sets)';
            app.CreateaseparateSimulinkfileperrequirementButton.Position = [11 7 485 22];

            % Create CreateanewSimulinkfileCheckBox
            app.CreateanewSimulinkfileCheckBox = uicheckbox(app.UIFigure);
            app.CreateanewSimulinkfileCheckBox.ValueChangedFcn = createCallbackFcn(app, @CreateanewSimulinkfileCheckBoxValueChanged, true);
            app.CreateanewSimulinkfileCheckBox.Text = 'Create a new Simulink file';
            app.CreateanewSimulinkfileCheckBox.Position = [125 108 161 29];
            app.CreateanewSimulinkfileCheckBox.Value = true;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = importLusTestOblFig

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end