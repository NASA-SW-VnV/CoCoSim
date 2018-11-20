%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ new_model_path, status ] = mcdc_tests(...
    model_full_path, exportToWs, mkHarnessMdl )
%MCDCTOSIMULINK try to bring back the MC-DC conditions to simulink level.

if ~exist(model_full_path, 'file')
    display_msg(['File not foudn: ' model_full_path],...
        MsgType.ERROR, 'mutation_tests', '');
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
[model_parent_path, slx_file_name, ~] = fileparts(model_full_path);
display_msg(['Generating mc-dc coverage Model for : ' slx_file_name],...
    MsgType.INFO, 'mutation_tests', '');
status = 0;


% Compile model
try
    [lus_full_path, xml_trace, ~, ~, ~, pp_model_full_path] = ...
        ToLustre(model_full_path);
    [output_dir, lus_file_name, ~] = fileparts(lus_full_path);
    [~, main_node, ~] = fileparts(lus_file_name);%remove .LUSTREC/.KIND2 from name.
    [~, slx_file_name, ~] = fileparts(pp_model_full_path);
catch ME
    display_msg(['Compilation failed for model ' slx_file_name], ...
        MsgType.ERROR, 'mcdcToSimulink', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
    status = 1;
    rethrow(ME);
end













% Generate MCDC lustre file from Simulink model Lustre file
try
    mcdc_file = LustrecUtils.generate_MCDCLustreFile(lus_full_path, output_dir);
catch ME
    display_msg(['MCDC generation failed for lustre file ' lus_full_path],...
        MsgType.ERROR, 'mcdcToSimulink', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
    status = 1;
    return;
end

try
    % generate test cases that covers the MC-DC conditions
    new_mcdc_file = LustrecUtils.adapt_lustre_file(mcdc_file, 'Kind2');
    [~, T] = Kind2Utils2.extractKind2CEX(new_mcdc_file, output_dir, main_node, ...
        ' --slice_nodes false --check_subproperties true ');
    
    if isempty(T)
        display_msg('No MCDC conditions were generated', MsgType.RESULT, 'mcdcToSimulink', '');
        return;
    end
    % add random test scenario with 100 steps, to compare the coverage.
    [ input_struct ] = random_tests( model_full_path, 100);
    input_struct.node_name = main_node;
    T = [input_struct, T];
    if exportToWs
        assignin('base', strcat(slx_file_name, '_mcdc_tests'), T);
        display_msg(['Generated test suite is saved in workspace under name: ' strcat(slx_file_name, '_mcdc_tests')],...
            MsgType.RESULT, 'mutation_tests', '');
    end
catch ME
    display_msg(['MCDC coverage generation failed for lustre file ' new_mcdc_file],...
        MsgType.ERROR, 'mcdcToSimulink', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
    status = 1;
    rethrow(ME);
end

% Create harness model
if ~mkHarnessMdl
    return;
end

% create new model
% we add a Postfix to differentiate it with the original Simulink model
new_model_name = strcat(slx_file_name,'_mcdc');
new_model_path = fullfile(output_dir, strcat(new_model_name,'.slx'));

display_msg(['Cocospec path: ' new_model_path ], MsgType.INFO, 'mcdcToSimulink', '');

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
[mcdc_IR_path, status] = LustrecUtils.generate_emf(mcdc_file, output_dir);

if status
    return;
end

% generate mcdc Simulink blocks

try
    [status, mcdc_model_path, mcdc_trace] = mcdc2slx(mcdc_IR_path, xml_trace, ...
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
    rethrow(ME);
end

% add mcdc blocks to Simulink model
try
    load_system(new_model_path);
    load_system(mcdc_model_path);
    nodes = mcdc_trace.traceRootNode.getElementsByTagName('Node');
    nb_mcdc = 0;
    for idx_node=0:nodes.getLength-1
        mcdc_blk_name = char(nodes.item(idx_node).getAttribute('block_name'));
        node_name = char(nodes.item(idx_node).getAttribute('node_name'));
        simulink_block_name = XMLUtils.get_Simulink_block_from_lustre_node_name(xml_trace, ...
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
                position  = BUtils.get_obs_position(new_model_name);
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
        add_block(mcdc_blk_name,...
            mcdc_dst_path);
        set_param(mcdc_dst_path, 'Position',[(x+100) y (x+250) (y+50)]);
        set_mask_parameters(mcdc_dst_path);
        dst_blk_portHandles = get_param(mcdc_dst_path, 'PortHandles');
        
        inputs = nodes.item(idx_node).getElementsByTagName('Input');
        for id_input=0:inputs.getLength-1
            
            block_name = ...
                inputs.item(id_input).getElementsByTagName('block_name').item(0).getTextContent;
            block_name = regexprep(char(block_name),strcat('^',slx_file_name,'/(\w)'),strcat(new_model_name,'/$1'));
            if getSimulinkBlockHandle(block_name) ~= -1
                %TODO: investigate the case where the block output is
                %not scalar.
                blk_portHandles = get_param(block_name, 'PortHandles');
                out_port_nb = char(...
                    inputs.item(id_input).getElementsByTagName('out_port_nb').item(0).getTextContent);
                add_line(simulink_block_name,...
                    blk_portHandles.Outport(str2num(out_port_nb)), ...
                    dst_blk_portHandles.Inport(id_input+1), ...
                    'autorouting', 'on');
            else
                display_msg(['Block not found ' block_name], MsgType.ERROR, 'mcdcToSimulink', '');
            end
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
    
    new_model_path = SLXUtils.makeharness(T, new_model_name, model_parent_path, '_harness');
    close_system(new_model_name, 0)
    open(new_model_path);
catch ME
    display_msg('MCDC to Simulink generation failed', MsgType.ERROR, 'mcdcToSimulink', '');
    display_msg(ME.message, MsgType.ERROR, 'mcdcToSimulink', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
    status = 1;
    rethrow(ME);
end
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

