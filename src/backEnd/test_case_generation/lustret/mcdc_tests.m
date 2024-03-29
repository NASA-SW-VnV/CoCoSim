%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ new_model_path, status ] = mcdc_tests(...
        model_full_path, exportToWs, mkHarnessMdl, nodisplay )
    %MCDCTOSIMULINK try to bring back the MC-DC conditions to simulink level.
    
    global KIND2 Z3 LUSTRET; 
    new_model_path = model_full_path;
    
    if isempty(KIND2)
        tools_config;
    end
    if ~exist(KIND2,'file')
        errordlg(sprintf('KIND2 model checker is not found in %s. Please set KIND2 path in tools_config.m under tools folder.', KIND2));
        status = 1;
        return;
    end
    status = coco_nasa_utils.MatlabUtils.check_files_exist(LUSTRET);
    if status
        msg = 'LUSTRET not found, please configure tools_config file under tools folder';
        errordlg(msg);
        status = 1;
        return;
    end
    
    if ~exist(model_full_path, 'file')
        display_msg(['File not foudn: ' model_full_path],...
            MsgType.ERROR, 'mcdc_tests', '');
        return;
    else
        model_full_path = which(model_full_path);
    end
    if ~exist('exportToWs', 'var') || isempty(exportToWs)
        exportToWs = 0;
    end
    if ~exist('mkHarnessMdl', 'var') || isempty(mkHarnessMdl)
        mkHarnessMdl = 0;
    end
    if ~exist('nodisplay', 'var') || isempty(nodisplay)
        nodisplay = 0;
    end
    [model_parent_path, slx_file_name, ~] = fileparts(model_full_path);
    display_msg(['Generating mc-dc coverage Model for : ' slx_file_name],...
        MsgType.INFO, 'mcdc_tests', '');
    
    
    % Compile model
    try
        options = {};
        if nodisplay
            options{1} = nasa_toLustre.utils.ToLustreOptions.NODISPLAY;
        end
        [lus_full_path, xml_trace, is_unsupported, ~, ~, pp_model_full_path] = ...
            nasa_toLustre.ToLustre(model_full_path, [], ...
            coco_nasa_utils.LusBackendType.LUSTREC, [], options{:});
        if is_unsupported
            display_msg('Model is not supported', MsgType.ERROR, 'validation', '');
            return;
        end
        [output_dir, lus_file_name, ~] = fileparts(lus_full_path);
        main_node = coco_nasa_utils.MatlabUtils.fileBase(lus_file_name);%remove .LUSTREC/.KIND2 from name.
        [~, slx_file_name, ~] = fileparts(pp_model_full_path);
        load_system(pp_model_full_path);
    catch ME
        display_msg(['Compilation failed for model ' slx_file_name], ...
            MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
        return;
    end
    
    % Generate MCDC lustre file from Simulink model Lustre file
    try
        mcdc_file = coco_nasa_utils.LustrecUtils.generate_MCDCLustreFile(lus_full_path, output_dir);
    catch ME
        display_msg(['MCDC generation failed for lustre file ' lus_full_path],...
            MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
        return;
    end
    
    try
        % generate test cases that covers the MC-DC conditions
        new_mcdc_file = coco_nasa_utils.LustrecUtils.adapt_lustre_file(mcdc_file, coco_nasa_utils.LusBackendType.KIND2);
        [syntax_status, output] = coco_nasa_utils.Kind2Utils.checkSyntaxError(new_mcdc_file, KIND2, Z3);
        if syntax_status
            display_msg(output, MsgType.DEBUG, 'mcdc_tests', '');
            display_msg('This model is not compatible for MC-DC generation.', MsgType.RESULT, 'mcdcToSimulink', '');
            status = 1;
            return;
        end
        [~, T] = coco_nasa_utils.Kind2Utils.extractKind2CEX(new_mcdc_file, output_dir, main_node, ...
            ' --slice_nodes false --check_subproperties true ');
        
        if isempty(T)
            display_msg('No MCDC conditions were generated', MsgType.RESULT, 'mcdcToSimulink', '');
            return;
        end
        % add random test scenario with 100 steps, to compare the coverage.
        %TODO change input_struct from dataset to signals/time struct.
        %[ input_struct ] = random_tests( model_full_path, 100);
        %input_struct.node_name = main_node;
        %T = [input_struct, T];
        if exportToWs
            assignin('base', strcat(slx_file_name, '_mcdc_tests'), T);
            display_msg(['Generated test suite is saved in workspace under name: ' strcat(slx_file_name, '_mcdc_tests')],...
                MsgType.RESULT, 'mcdc_tests', '');
        end
    catch ME
        display_msg(['MCDC coverage generation failed for lustre file ' mcdc_file],...
            MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
        return;
    end
    
    % Create harness model
    if ~mkHarnessMdl
        return;
    else
        %% TODO Work in progress. Remove this when fixing the MC-DC importer.
        %         display_msg('Adding MC-DC conditions to Simulink is not currently supported. Work in progress!',...
        %             MsgType.RESULT, 'mcdc_tests', '');
        %         return;
    end
    
    % create new model
    % we add a Postfix to differentiate it with the original Simulink model
    new_model_name = strcat(slx_file_name,'_mcdc');
    new_model_path = fullfile(output_dir, strcat(new_model_name,'.slx'));
    
    display_msg(['MCDC file path: ' new_model_path ], MsgType.INFO, 'mcdcToSimulink', '');
    
    if exist(new_model_path,'file')
        if bdIsLoaded(new_model_name)
            close_system(new_model_name,0)
        end
        delete(new_model_path);
    end
    
    load_system(model_full_path);
    close_system(new_model_path,0)
    save_system(slx_file_name, new_model_path, 'OverwriteIfChangedOnDisk', true);
    load_system(new_model_path);
    % Generate IR of MCDC file
    [mcdc_IR_path, status] = coco_nasa_utils.LustrecUtils.generate_emf(mcdc_file, output_dir);
    
    if status
        return;
    end
    
    %% generate mcdc Simulink blocks
    
    try
        [status, mcdc_model_path, mcdc_trace] = MCDC2SLX.transform(mcdc_IR_path, xml_trace, ...
            output_dir, ...
            [], ...
            [], ...
            1);
        if status
            return;
        end
        [~, mcdc_subsys, ~] = fileparts(mcdc_model_path);
        
    catch ME
        display_msg('MCDC to Simulink generation failed', MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
        return;
    end
    
    %% add mcdc blocks to Simulink model
    try
        
        status = addMCDCBlocksToSLX(new_model_path, slx_file_name, new_model_name, ...
            mcdc_model_path, mcdc_subsys, mcdc_trace, xml_trace);
        
    catch ME
        display_msg('MCDC to Simulink generation failed', MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
    end
    
    
    %% Create harness model
    try
        new_model_path = coco_nasa_utils.SLXUtils.makeharness(T, new_model_name, model_parent_path, '_harness');
        close_system(new_model_name, 0)
        if ~nodisplay
            open(new_model_path);
        end
    catch ME
        display_msg('Create harness model failed', MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
    end
end
%% add mcdc blocks function
function [status] = addMCDCBlocksToSLX(new_model_path, slx_file_name, new_model_name, ...
        mcdc_model_path, mcdc_subsys, mcdc_trace, xml_trace)
    if ~bdIsLoaded('pp_lib'); load_system('pp_lib.slx'); end
    load_system(new_model_path);
    load_system(mcdc_model_path);
    nodes = mcdc_trace.traceRootNode.getElementsByTagName('Node');
    nb_mcdc = 0;
    status = 0;
    for idx_node=0:nodes.getLength-1
        failed = false;
        blksHamdles = [];
        linesHamdles = [];
        mcdc_blk_name = char(nodes.item(idx_node).getAttribute('OriginPath'));
        node_name = char(nodes.item(idx_node).getAttribute('NodeName'));
        simulink_block_name = nasa_toLustre.utils.SLX2Lus_Trace.get_Simulink_block_from_lustre_node_name(xml_trace, ...
            node_name, slx_file_name, new_model_name);
        isBaseName = false;
        if isempty(simulink_block_name)
            continue;
        elseif strcmp(simulink_block_name,slx_file_name)
            simulink_block_name = new_model_name;
            isBaseName = true;
        end
        
        %for having a good order of blocks
        try
            if isBaseName
                position  = coco_nasa_utils.SLXUtils.get_obs_position(new_model_name);
            else
                position  = get_param(simulink_block_name,'Position');
            end
            
        catch ME
            msg = sprintf('There is no block called %s in your model\n', simulink_block_name);
            msg1 = [msg, sprintf('if the block %s exists, make sure it is atomic', simulink_block_name)];
            msg2 = sprintf('%s\n%s\n', msg1, ME.getReport());
            warndlg(msg1,'CoCoSim: Warning');
            fprintf(msg2);
            continue;
        end
        x = position(1);
        y = position(2)+250;
        
        %Adding the cocospec subsystem related with the Simulink subsystem
        %"simulink_block_name"
        mcdc_dst_path = fullfile(simulink_block_name,'MC-DC conditions');
        n = 1;
        while getSimulinkBlockHandle(mcdc_dst_path) ~= -1
            mcdc_dst_path = strcat(mcdc_dst_path, num2str(n));
            n = n + 1;
            y = y+250;
        end
        h = add_block(mcdc_blk_name,...
            mcdc_dst_path);
        blksHamdles(end+1) = h;
        set_param(mcdc_dst_path, 'Position',[(x+100) y (x+250) (y+50)]);
        set_mask_parameters(mcdc_dst_path);
        dst_blk_portHandles = get_param(mcdc_dst_path, 'PortHandles');
        try
            
            inputs = nodes.item(idx_node).getElementsByTagName('Inport');
            for id_input=0:inputs.getLength-1
                
                block_name = ...
                    inputs.item(id_input).getElementsByTagName('OriginPath').item(0).getTextContent;
                block_name = regexprep(char(block_name),strcat('^',slx_file_name,'/(\w)'),strcat(new_model_name,'/$1'));
                if getSimulinkBlockHandle(block_name) ~= -1
                    %TODO: investigate the case where the block output is
                    %not scalar.
                    blk_portHandles = get_param(block_name, 'PortHandles');
                    port_nb = str2num(char(...
                        inputs.item(id_input).getElementsByTagName('PortNumber').item(0).getTextContent));
                    portWidth = str2num(char(...
                        inputs.item(id_input).getElementsByTagName('Width').item(0).getTextContent));
                    portIndex = (char(...
                        inputs.item(id_input).getElementsByTagName('Index').item(0).getTextContent));
                    portType = char(inputs.item(id_input).getElementsByTagName('PortType').item(0).getTextContent());
                    if strcmp(portType, 'Outports')
                        srcPortHandle = blk_portHandles.Outport(port_nb);
                    else
                        line = get_param(blk_portHandles.Inport(port_nb), 'line');
                        srcPortHandle = get_param(line, 'SrcPortHandle');
                    end
                    % take too much to compile model for many times
                    %                     compiledBusType = coco_nasa_utils.SLXUtils.getCompiledParam(srcPortHandle, ...
                    %                         'CompiledBusType');
                    %                     if ~strcmp(compiledBusType,'NOT_BUS')
                    %                         continue;
                    %                     end
                    % Second solution
                    sh = get_param(srcPortHandle, 'SignalHierarchy');
                    if ~(isempty(sh.BusObject) && isempty(sh.Children))
                        %TODO: support bus signals linking.
                        failed = true;
                        display_msg(['Bus Signals are not supported for MCDC to Simulink generation for: ' simulink_block_name],...
                            MsgType.ERROR, 'mcdcToSimulink', '');
                        break;
                    end
                    if portWidth > 1
                        
                        n = 1;
                        pos = get_param(dst_blk_portHandles.Inport(id_input+1),'Position');
                        x = pos(1); y = pos(2)-150;
                        selector_path = fullfile(simulink_block_name,'InlinedSelector');
                        while getSimulinkBlockHandle(selector_path) ~= -1
                            selector_path =fullfile(simulink_block_name,strcat('InlinedSelector', num2str(n)));
                            n = n + 1;
                        end
                        h = add_block('pp_lib/InlinedSelector',...
                            selector_path, ...
                            'index', portIndex, ...
                            'Position', [(x-10) y (x+10) (y+50)]);
                        blksHamdles(end+1) = h;
                        if h > 0
                            sel_portHandles = get_param(h, 'PortHandles');
                            l = add_line(simulink_block_name,...
                                srcPortHandle, ...
                                sel_portHandles.Inport(1), ...
                                'autorouting', 'on');
                            linesHamdles(end+1) = l;
                            l = add_line(simulink_block_name,...
                                sel_portHandles.Outport(1), ...
                                dst_blk_portHandles.Inport(id_input+1), ...
                                'autorouting', 'on');
                            linesHamdles(end+1) = l;
                        end
                    else
                        l = add_line(simulink_block_name,...
                            srcPortHandle, ...
                            dst_blk_portHandles.Inport(id_input+1), ...
                            'autorouting', 'on');
                        linesHamdles(end+1) = l;
                    end
                else
                    display_msg(['Block not found ' block_name], MsgType.ERROR, 'mcdcToSimulink', '');
                end
            end
            if failed
                delete_block(blksHamdles);
                delete_line(linesHamdles);
            end
        catch ME
            display_msg(['MCDC to Simulink generation failed for: ' mcdc_dst_path],...
                MsgType.ERROR, 'mcdcToSimulink', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
            status = 1;
        end
        nb_mcdc = nb_mcdc + 1;
        
    end
    
    if nb_mcdc == 0
        display_msg('No MCDC conditions were generated', MsgType.RESULT, 'mcdcToSimulink', '');
        return;
    end
    
    % Save the system
    save_system(mcdc_subsys);
    save_system(new_model_name,new_model_path,'OverwriteIfChangedOnDisk',true);
    close_system(mcdc_subsys,0)
end

%% Returns the Display parameter value for the Observer block
function set_mask_parameters(observer_path)
    
    mask = Simulink.Mask.create(observer_path);
    mask.Display = sprintf('%s', get_observer_display());
    mask.IconUnits = 'normalized';
    mask.Type = 'MCDC';
    mask.Description = get_obs_description();
    set_param(observer_path, 'ForegroundColor', 'red');
    set_param(observer_path, 'BackgroundColor', 'white');
    
end
function [display] = get_observer_display()
    display = sprintf('color(''red'')\n');
    display = [display sprintf('text(0.5, 0.5, [''MC-DC: '''''' get_param(gcb,''name'') ''''''''], ''horizontalAlignment'', ''center'');\n')];
    display = [display 'text(0.99, 0.03, ''{\bf\fontsize{12}'];
    display = [display char('MC-DC')];
    display = [display '}'', ''hor'', ''right'', ''ver'', ''bottom'', ''texmode'', ''on'');'];
end

function [desc] = get_obs_description()
    
    desc = sprintf('MC-DC subsytem containing MC-DC conditions for the current subsystem.');
end

