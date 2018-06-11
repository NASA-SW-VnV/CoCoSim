%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of CoCoSim.
% Copyright (C) 2014-2016  Carnegie Mellon University
% Copyright (C) 2018  The university of Iowa
% Authors: Temesghen Kahsai, Hamza Bourbouh, Mudathir Mahgoub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef VerificationMenu

    methods(Static)
        function schema = verify(callbackInfo)
            schema = sl_action_schema;
            schema.label = 'Verify';
            if evalin( 'base', '~exist(''MODEL_CHECKER'',''var'')' ) == 1 || ...
                        strcmp(evalin( 'base', 'MODEL_CHECKER' ) ,'Kind2')
                schema.callback = @VerificationMenu.kindCallback;
            else
                if strcmp(evalin( 'base', 'MODEL_CHECKER' ) ,'JKind')
                    schema.callback = @jkindCallback;
                end
            end
        end % verify
        
        function schema = verifyUsing(callbackInfo)
            schema = sl_container_schema;
            schema.label = 'Verify using ...';
            schema.statustip = 'Verify the current model with CoCoSim';
            schema.autoDisableWhen = 'Busy';
            schema.childrenFcns = {@VerificationMenu.getZustre, ...
                @VerificationMenu.getKind, @VerificationMenu.getJKind};
        end % verifyUsing
        
        function kindCallback(callbackInfo)
            clear;
            [prog_path, fname, ext] = fileparts(mfilename('fullpath'));
            assignin('base', 'SOLVER', 'K');
            assignin('base', 'RUST_GEN', 0);
            assignin('base', 'C_GEN', 0);
            VerificationMenu.runCoCoSim;
        end % kindCallback
        
        function jkindCallback(callbackInfo)
            clear;
            [prog_path, fname, ext] = fileparts(mfilename('fullpath'));
            assignin('base', 'SOLVER', 'J');
            assignin('base', 'RUST_GEN', 0);
            assignin('base', 'C_GEN', 0);
            VerificationMenu.runCoCoSim;
        end % jkindCallback

        function zustreCallback(callbackInfo)
            clear;
            assignin('base', 'SOLVER', 'Z');
            assignin('base', 'RUST_GEN', 0);
            assignin('base', 'C_GEN', 0);
            VerificationMenu.runCoCoSim;
        end % zustreCallback
        
        function runCoCoSim
            [path, name, ext] = fileparts(mfilename('fullpath'));
            addpath(fullfile(path, 'utils'));
            try
                simulink_name = VerificationMenu.get_file_name(gcs);
                cocosim_window(simulink_name);
                %       cocoSim(simulink_name); % run cocosim
            catch ME
                if strcmp(ME.identifier, 'MATLAB:badsubscript')
                    msg = ['Activate debug message by running cocosim_debug=true', ...
                        ' to get more information where the model in failing'];
                    e_msg = sprintf('Error Msg: %s \n Action:\n\t %s', ME.message, msg);
                    display_msg(e_msg, Constants.ERROR, 'cocoSim', '');
                    display_msg(ME.getReport(),Constants.DEBUG,'cocoSim','');
                elseif strcmp(ME.identifier,'MATLAB:MException:MultipleErrors')
                    msg = 'Make sure that the model can be run (i.e. most probably missing constants)';
                    d_msg = sprintf('Error Msg: %s', ME.getReport());
                    display_msg(d_msg, Constants.DEBUG, 'cocoSim', '');
                    display_msg(msg, Constants.ERROR, 'cocoSim', '');
                elseif strcmp(ME.identifier, 'Simulink:Commands:ParamUnknown')
                    msg = 'Run CoCoSim on the most top block of the model';
                    e_msg = sprintf('Error Msg: %s \n Action:\n\t %s', ME.message, msg);
                    display_msg(e_msg, Constants.ERROR, 'cocoSim', '');
                    display_msg(ME.getReport(),Constants.DEBUG,'cocoSim','');
                else
                    display_msg(ME.message,Constants.ERROR,'cocoSim','');
                    display_msg(ME.getReport(),Constants.DEBUG,'cocoSim','');
                end

            end
        end % runCoCoSim
        
        
        function schema = getKind(callbackInfo)
            schema = sl_action_schema;
            schema.label = 'Kind2';
            schema.callback = @VerificationMenu.kindCallback;
        end % getKind

        function schema = getJKind(callbackInfo)
            schema = sl_action_schema;
            schema.label = 'JKind';
            schema.callback = @VerificationMenu.jkindCallback;
        end % getJKind

        function schema = getZustre(callbackInfo)
            schema = sl_action_schema;
            schema.label = 'Zustre';
            schema.callback = @VerificationMenu.zustreCallback;
        end % getZustre
        
        function fname = get_file_name(gcs)
            names = regexp(gcs,'/','split');
            fname = get_param(names{1},'FileName');
        end % get_file_name
        
        
        function schema = displayHtmlVerificationResults(callbackInfo)
            schema = sl_action_schema;            
            schema.label = 'Verification Results' ;      
            schema.statustip = 'Verification Results';
            schema.autoDisableWhen = 'Busy';            
            schema.callback = @VerificationMenu.displayHtmlVerificationResultsCallback;
        end
        
        function displayHtmlVerificationResultsCallback(callbackInfo)
             % get the verification results from the model workspace
            modelWorkspace = get_param(callbackInfo.studio.App.blockDiagramHandle,'modelworkspace');   
            verificationResults = modelWorkspace.getVariable('verificationResults');    
            
            modelPath = get_param(callbackInfo.studio.App.blockDiagramHandle, 'FileName');
            
            modelPath = strrep(modelPath, '\', '\\');            

            filePath = fileparts(mfilename('fullpath'));
            filePath = fullfile(filePath, 'cocoSpecVerify', 'utils', 'html');
            html = fileread(fullfile(filePath, 'verificationResultsTemplate.html'));
            json = json_encode(verificationResults);    
            html = strrep(html, '[(verificationResults)]', json);
            html = strrep(html, '[(modelPath)]', modelPath);
            htmlFile = strcat(tempname, '.html');
            fid = fopen(htmlFile, 'w');
            fprintf(fid,'%s', html);
            fclose(fid);    

            % check css and js files

            tempFolder = fileparts(tempname);
            
            if ~ exist(fullfile(tempFolder, 'jquery.min.js'), 'file')
                copyfile(fullfile(filePath, 'js', 'jquery.min.js'), ...
                fullfile(tempFolder, 'jquery.min.js')); 
            end
            
            if ~ exist(fullfile(tempFolder, 'fa-svg-with-js.css'), 'file')
                copyfile(fullfile(filePath, 'css', 'fa-svg-with-js.css'), ...
                fullfile(tempFolder, 'fa-svg-with-js.css')); 
            end
            
            if ~ exist(fullfile(tempFolder, 'fontawesome-all.js'), 'file')
                copyfile(fullfile(filePath, 'js', 'fontawesome-all.js'), ...
                fullfile(tempFolder, 'fontawesome-all.js')); 
            end
            
            if ~ exist(fullfile(tempFolder, 'bootstrap.min.css'), 'file')
                copyfile(fullfile(filePath, 'css', 'bootstrap.min.css'), ...
                fullfile(tempFolder, 'bootstrap.min.css')); 
            end
            
            if ~ exist(fullfile(tempFolder, 'popper.min.js'), 'file')
                copyfile(fullfile(filePath, 'js', 'popper.min.js'), ...
                fullfile(tempFolder, 'popper.min.js')); 
            end
            
            if ~ exist(fullfile(tempFolder, 'bootstrap.min.js'), 'file')
                copyfile(fullfile(filePath, 'js', 'bootstrap.min.js'), ...
                fullfile(tempFolder, 'bootstrap.min.js')); 
            end
            
            % open the web page in matlab browser
            url = ['file:///',htmlFile];
            web(url);
            
        end
        
        function schema = compositionalOptions(callbackInfo)
            schema = sl_container_schema;
            schema.label = 'Compositional Abstract';
            schema.statustip = 'Compositional Abstract';
            schema.autoDisableWhen = 'Busy';
            % get the compositional options from the model workspace
            modelWorkspace = get_param(callbackInfo.studio.App.blockDiagramHandle,'modelworkspace');   
            compositionalMap = modelWorkspace.getVariable('compositionalMap');    

            % add a menu item for each option
            index = 1;
            for i = 1: length(compositionalMap.analysisNames)        
                schema.childrenFcns{index} = {@VerificationMenu.compositionalKey, compositionalMap.analysisNames{i}};
                index = index + 1;
                for j=1: length(compositionalMap.compositionalOptions{i})
                    data.label = compositionalMap.compositionalOptions{i}{j};
                    data.selectedOption = compositionalMap.selectedOptions(i);
                    data.currentOption = j;
                    data.currentAnalysis = i;
                    schema.childrenFcns{index} = {@VerificationMenu.compositionalOption, data};
                    index = index + 1;
                end
                schema.childrenFcns{index} = 'separator';
                index = index + 1;
            end    
        end

        function schema = compositionalKey(callbackInfo)
            schema = sl_action_schema;
            label = callbackInfo.userdata;    
            schema.label = label;      
            schema.state = 'Disabled';    
        end

        function schema = compositionalOption(callbackInfo)
            schema = sl_toggle_schema;
            data = callbackInfo.userdata;    
            if length(data.label) == 0
                schema.label = 'No abstract';
            else
                schema.label = data.label;
            end          
            if data.selectedOption == data.currentOption
                schema.checked = 'checked';    
            else
                schema.checked = 'unchecked';    
            end

            schema.callback = @VerificationMenu.compositionalOptionCallback;
            schema.userdata = data;

        end

        function compositionalOptionCallback(callbackInfo)    
            data = callbackInfo.userdata;    
            modelWorkspace = get_param(callbackInfo.studio.App.blockDiagramHandle,'modelworkspace');   
            verificationResults = modelWorkspace.getVariable('verificationResults');
            compositionalMap = modelWorkspace.getVariable('compositionalMap');    
            compositionalMap.selectedOptions(data.currentAnalysis) = data.currentOption; 
            assignin(modelWorkspace,'compositionalMap',compositionalMap);
            displayVerificationResults(verificationResults, compositionalMap);
        end

        
        
    end
 end