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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function [valid, ...
    lustrec_failed,...
    lustrec_binary_failed,...
    sim_failed] = validate_lus2slx( lus_file_path,...
    main_node, ...
    tests_method, ...
    model_checker, ...
    deep_CEX)
%VALIDATE_LUS2SLX validate the translation lustre 2 simulink by equivalence
%testing or equivalence checking.
[lus_dir, lus_fname, ~] = fileparts(lus_file_path);
if nargin < 2 || isempty(main_node)
    main_node = coco_nasa_utils.SLXUtils.adapt_block_name(coco_nasa_utils.MatlabUtils.fileBase(lus_fname));
end
if ~exist('tests_method', 'var')
    tests_method = 1;
end
if ~exist('model_checker', 'var')
    model_checker = 'KIND2';
end
if ~exist('stop_at_first_cex', 'var')
    deep_CEX = 0;
end

OldPwd = pwd;


%%
valid = -1;
lustrec_failed = -1;
lustrec_binary_failed = -1;
sim_failed = -1;

output_dir = fullfile(lus_dir, 'cocosim_tmp', lus_fname);
%% generate EMF
tools_config;
status = coco_nasa_utils.MatlabUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
if status
    return;
end
[emf_path, status] = LustrecUtils.generate_emf(lus_file_path, output_dir, LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR);
if status
    return;
end
%% generate Lusi file
[lusi_path, status] = LustrecUtils.generate_lusi(lus_file_path, LUSTREC );
if status
    return;
end
%% extract SLX for all nodes
[status, translated_nodes_path, ~] = lus2slx(emf_path, output_dir);
if status
    cd(OldPwd);
    return;
end

[~, translated_nodes, ~] = fileparts(translated_nodes_path);
load_system(translated_nodes_path);

data = coco_nasa_utils.MatlabUtils.read_json(emf_path);
nodes = data.nodes;
emf_nodes_names = fieldnames(nodes)';
lusi_text = fileread(lusi_path);
nodes_names = {};
for node_idx =1:numel(emf_nodes_names)
    name = emf_nodes_names{node_idx};
    original_name = nodes.(name).original_name;
    pattern = strcat('(node|function)\s+',original_name,'\s*\(');
    tokens = regexp(lusi_text, pattern,'match');
    if ~isempty(tokens) && ~(coco_nasa_utils.MatlabUtils.endsWith(original_name, '_unless') || coco_nasa_utils.MatlabUtils.endsWith(original_name, '_handler_until'))
        nodes_names{numel(nodes_names) + 1} = name;
    end
end
orig_names = arrayfun(@(x)  nodes.(x{1}).original_name,...
        nodes_names, 'UniformOutput', false);
for node_idx =0:numel(nodes_names)
    
    if node_idx==0
        if ismember(main_node, orig_names)
            idx = ismember(orig_names, main_node);
            node_name = coco_nasa_utils.SLXUtils.adapt_block_name(nodes_names{idx});
            original_node_name = orig_names{idx};
        else
            continue;
        end
    else
        original_node_name = nodes.(nodes_names{node_idx}).original_name;
        node_name = coco_nasa_utils.SLXUtils.adapt_block_name(nodes_names{node_idx});
        if strcmp(original_node_name, main_node)
            continue;
        end
    end
    %% extract the main node Subsystem
    base_name = regexp(lus_fname,'\.','split');
    new_model_name = coco_nasa_utils.SLXUtils.adapt_block_name(strcat(base_name{1},'_', node_name));
    new_name = fullfile(output_dir, strcat(new_model_name,'.slx'));
    if exist(new_name,'file')
        if bdIsLoaded(new_model_name)
            close_system(new_model_name,0)
        end
        delete(new_name);
    end
    close_system(new_model_name,0);
    model_handle = new_system(new_model_name);
    
    
    main_block_path = strcat(new_model_name,'/', node_name);
    node_subsystem = strcat(translated_nodes, '/', node_name);
    add_block(node_subsystem,...
        main_block_path);
    portHandles = get_param(main_block_path, 'PortHandles');
    nb_inports = numel(portHandles.Inport);
    nb_outports = numel(portHandles.Outport);
    m = max(nb_inports, nb_outports);
    set_param(main_block_path,'Position',[100 0 (100+250) (0+50*m)]);
    
    for i=1:nb_inports
        p = get_param(portHandles.Inport(i), 'Position');
        x = p(1) - 50;
        y = p(2);
        inport_name = strcat(new_model_name,'/In',num2str(i));
        add_block('simulink/Ports & Subsystems/In1',...
            inport_name,...
            'Position',[(x-10) (y-10) (x+10) (y+10)]);
        SrcBlkH = get_param(inport_name,'PortHandles');
        add_line(new_model_name, SrcBlkH.Outport(1), portHandles.Inport(i), 'autorouting', 'on');
    end
    
    for i=1:nb_outports
        p = get_param(portHandles.Outport(i), 'Position');
        x = p(1) + 50;
        y = p(2);
        outport_name = strcat(new_model_name,'/Out',num2str(i));
        add_block('simulink/Ports & Subsystems/Out1',...
            outport_name,...
            'Position',[(x-10) (y-10) (x+10) (y+10)]);
        DstBlkH = get_param(outport_name,'PortHandles');
        add_line(new_model_name, portHandles.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
    end
    %% Save system
    configSet = getActiveConfigSet(model_handle);
    set_param(configSet, 'Solver', 'FixedStepDiscrete', 'FixedStep', '1');
    save_system(model_handle,new_name,'OverwriteIfChangedOnDisk',true);
    
    % open(new_name)
    
    %% launch validation
    
    if ~exist(output_dir, 'dir'); mkdir(output_dir); end
    try
        [valid, ...
            lustrec_failed,...
            lustrec_binary_failed,...
            sim_failed] = compare_slx_lus(new_name, ...
            lus_file_path, ...
            original_node_name, ...
            output_dir,...
            tests_method,...
            model_checker);
        if ~valid
            display_msg(['Node ' original_node_name ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
            if deep_CEX
                break;
            end
        end
        if node_idx==0 && (prod(valid) ==1  || (deep_CEX == 0))
            break;
        elseif node_idx>0 && ~lustrec_failed && ~sim_failed && ~lustrec_binary_failed && ~valid && (deep_CEX == 0)
            break;
        end
    catch ME
        display_msg(ME.message, MsgType.ERROR, 'validation', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
        cd(OldPwd);
        return;
    end
    
end
cd(OldPwd);
close_system(translated_nodes,0);

%% clean tmp files
system(['rm ' lusi_path]);


%Already done above, we loop on all nodes.
% if ~lustrec_failed && ~sim_failed && ~lustrec_binary_failed && ~valid && (deep_CEX > 0)
%     %get tracability    
%     validate_components(new_name, new_model_name, new_model_name,...
%         lus_file_path, emf_trace_file,base_name{1}, output_dir,...
%         deep_CEX, 1, tests_method, model_checker);
% end
end

function validate_components(file_path, file_name, block_path, ...
    lus_file_path, trace_file_name, base_name, output_dir, ...
    deep_CEX, deep_current, tests_method, model_checker)
ss = find_system(block_path, 'SearchDepth',1, 'BlockType','SubSystem');
if ~exist('deep_current', 'var')
    deep_current = 1;
end
for i=1:numel(ss)
    if strcmp(ss{i}, block_path)
        continue;
    end
    display_msg(['Validating SubSystem ' ss{i}], MsgType.INFO, 'validation', '');
    origin_ss = regexprep(ss{i}, strcat('^',file_name,'/'), strcat(base_name,'_emf/'));
    node_name = SLX2Lus_Trace.get_lustre_node_from_Simulink_block_name(trace_file_name,origin_ss);
    if ~strcmp(node_name, '')
        [new_model_path, ~] = coco_nasa_utils.SLXUtils.crete_model_from_subsystem(file_name, ss{i}, output_dir );
        try
            [valid, ~, ~, ~] = compare_slx_lus(new_model_path, lus_file_path, node_name, output_dir, tests_method, model_checker);
            if ~valid
                display_msg(['SubSystem ' ss{i} ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
                load_system(file_path);
                validate_components(file_path, file_name, ss{i}, lus_file_path, trace_file_name,base_name,  output_dir, deep_CEX, deep_current+1, tests_method, model_checker);
                if deep_current > deep_CEX; return;end
            else
                display_msg(['SubSystem ' ss{i} ' is valid'], MsgType.RESULT, 'validation', '');
            end
        catch ME
            display_msg(ME.message, MsgType.ERROR, 'validation', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
            rethrow(ME);
        end
    else
        display_msg(['No node for subsytem ' ss{i} ' is found'], MsgType.INFO, 'validation', '');
    end
end

end

