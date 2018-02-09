%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MCDC2SLX translate MC-DC conditions an EMF json file to Simulink blocks.
%Every node is translated to a subsystem. If OnlyMainNode is true than only
%the main node specified
%in main_node argument will be kept in the final simulink model.
function [status,...
    new_model_path, ...
    mcdc_trace] = mcdc2slx(...
    json_path, ...
    mdl_trace, ...
    output_dir, ...
    new_model_name, ...
    main_node, ...
    organize_blocks)

%% Init
[coco_dir, cocospec_name, ~] = fileparts(json_path);
if ~exist('mdl_trace', 'var') || isempty(mdl_trace)
    display_msg(...
        'Traceability from Simulink to Lustre is required',...
        MsgType.ERROR,...
        'create_emf_verif_file', '');
    return;
end

if ~exist('main_node', 'var') || isempty(main_node)
    onlyMainNode = false;
else
    onlyMainNode = true;
end
if ~exist('organize_blocks', 'var') || isempty(organize_blocks)
    organize_blocks = true;
end

base_name = regexp(cocospec_name,'\.','split');
if ~exist('new_model_name', 'var') || isempty(new_model_name)
    if onlyMainNode
        new_model_name = BUtils.adapt_block_name(strcat(base_name{1}, '_mcdc_', main_node));
    else
        new_model_name = BUtils.adapt_block_name(strcat(base_name{1}, '_mcdc'));
    end
end

%%
try
    if ischar(mdl_trace)
        DOMNODE = xmlread(mdl_trace);
        mdlTraceRoot = DOMNODE.getDocumentElement;
    elseif isa(mdl_trace, 'XML_Trace')
        mdlTraceRoot = mdl_trace.traceRootNode;
    else
        mdlTraceRoot = mdl_trace;
    end
catch
    display_msg(...
        ['file ' cocosim_trace_file ' can not be read as xml file'],...
        MsgType.ERROR,...
        'create_emf_verif_file', '');
    return;
end

status = 0;
display_msg('Runing MCDC2SLX on EMF file', MsgType.INFO, 'MCDC2SLX', '');

if nargin < 2
    output_dir = coco_dir;
end

data = BUtils.read_json(json_path);

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

new_model_path = fullfile(output_dir,strcat(new_model_name,'.slx'));
if exist(new_model_path,'file')
    if bdIsLoaded(new_model_name)
        close_system(new_model_name,0)
    end
    delete(new_model_path);
end
close_system(new_model_name,0);
model_handle = new_system(new_model_name);

trace_file_name = fullfile(output_dir, ...
    strcat(cocospec_name, '.mcdc.trace.xml'));
mcdc_trace = XML_Trace(new_model_path, trace_file_name);
mcdc_trace.init();
% save_system(model_handle,new_name);

x = 200;
y = -50;

nodes = data.nodes;
emf_fieldnames = fieldnames(nodes)';
if onlyMainNode
    nodes_names = arrayfun(@(x)  nodes.(x{1}).original_name,...
        emf_fieldnames, 'UniformOutput', false);
    if ~ismember(main_node, nodes_names)
        msg = sprintf('Node "%s" not found in JSON "%s"', ...
            main_node, json_path);
        display_msg(msg, MsgType.ERROR, 'MCDC2SLX', '');
        status = 1;
        new_model_path = '';
        close_system(new_model_name,0);
        trace_file_name = '';
        return
    end
    node_idx = ismember(nodes_names, main_node);
    node_name = emf_fieldnames{node_idx};
    node_block_path = fullfile(new_model_name, BUtils.adapt_block_name(main_node));
    block_pos = [(x+100) y (x+250) (y+50)];
    mcdc_node_process(new_model_name, nodes, node_name, node_block_path, mdlTraceRoot, block_pos, mcdc_trace);
else
    for node = emf_fieldnames
        try
            node_name = BUtils.adapt_block_name(node{1});
            display_msg(...
                sprintf('Processing node "%s" ',node_name),...
                MsgType.INFO, 'MCDC2SLX', '');
            y = y + 150;
            
            block_pos = [(x+100) y (x+250) (y+50)];
            node_block_path = fullfile(new_model_name,node_name);
            mcdc_node_process(new_model_name, nodes, node{1}, node_block_path, mdlTraceRoot, block_pos,mcdc_trace);
            
        catch ME
            display_msg(['couldn''t translate node ' node{1} ' to Simulink'], MsgType.ERROR, 'MCDC2SLX', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'MCDC2SLX', '');
            %         continue;
            status = 1;
            return;
        end
    end
end


% Remove From Goto blocks and organize the blocks positions
if organize_blocks
    goto_process( new_model_name );
    blocks_position_process( new_model_name,2 );
end
% Write traceability informations
mcdc_trace.write();
configSet = getActiveConfigSet(model_handle);
set_param(configSet, 'Solver', 'FixedStepDiscrete');
save_system(model_handle,new_model_path,'OverwriteIfChangedOnDisk',true);

% open_system(model_handle);
end


%%
function mcdc_node_process(new_model_name, nodes, node, node_block_path, mdlTraceRoot, block_pos, xml_trace)
mcdc_variables_names = mcdcVariables(nodes.(node));
display_msg([num2str(numel(mcdc_variables_names)) ' mc-dc conditions has been generated'...
    ' for node ' nodes.(node).original_name], MsgType.INFO, 'mcdc2slx', '');
if ~isempty(mcdc_variables_names)
    % extract "lhs" names from instructions
    blk_exprs = nodes.(node).instrs;
    lhs_instrID_map = containers.Map();
    lhs_rhs_map = containers.Map();
    for var = fieldnames(blk_exprs)'
        switch blk_exprs.(var{1}).kind
            case 'branch'
                lhs_list = blk_exprs.(var{1}).outputs;
            otherwise
                lhs_list = blk_exprs.(var{1}).lhs;
        end
        
        % extract "rhs" names from instructions
        rhs_list = {};
        switch blk_exprs.(var{1}).kind
            case {'pre', 'local_assign'}
                rhs_type = blk_exprs.(var{1}).rhs.type;
                if strcmp(rhs_type, 'variable')
                    rhs_list = blk_exprs.(var{1}).rhs.value;
                end
                
            case 'reset' % lhs = rhs;
                rhs_list = blk_exprs.(var{1}).rhs;
                
            case {'operator', 'functioncall', 'statelesscall', 'statefulcall'}
                for i=1:numel(blk_exprs.(var{1}).args)
                    rhs_list{i} = blk_exprs.(var{1}).args(i).value;
                end
            case 'branch'
                blk_inputs = blk_exprs.(var{1}).inputs;
                for i=1:numel(blk_inputs)
                    rhs_list{i} = blk_inputs(i).name;
                end
        end
        if iscell(lhs_list)
            for i=1:numel(lhs_list)
                lhs_instrID_map(lhs_list{i}) = var{1};
                lhs_rhs_map(lhs_list{i}) = rhs_list;
            end
        else
            lhs_instrID_map(lhs_list) = var{1};
            lhs_rhs_map(lhs_list) = rhs_list;
        end
    end
    
    % get variables original names
    originalNamesMap = containers.Map();
    for input=nodes.(node).inputs
        originalNamesMap(input.name) = input.original_name;
    end
    for output=nodes.(node).outputs
        originalNamesMap(output.name) = output.original_name;
    end
    for local=nodes.(node).locals
        originalNamesMap(local.name) = local.original_name;
    end
    % get tracable variables names
    traceable_variables = XMLUtils.get_tracable_variables(mdlTraceRoot, nodes.(node).original_name);
    
    [instructionsIDs, inputList]= get_mcdc_instructions(mcdc_variables_names, ...
        lhs_instrID_map, lhs_rhs_map, originalNamesMap, traceable_variables);
    
    % creat mcdc block
    x2 = 200;
    y2= -50;
    
    if ~isempty(xml_trace)
        xml_trace.create_Node_Element(node_block_path,  nodes.(node).original_name);
        xml_trace.create_Inputs_Element();
    end
    add_block('built-in/Subsystem', node_block_path);%,...
    %             'TreatAsAtomicUnit', 'on');
    set_param(node_block_path, 'Position', block_pos);
    
    % Outputs
    
    [x2, y2] = process_mcdc_outputs(node_block_path, mcdc_variables_names, '', x2, y2);
    
    
    % Inputs
    blk_inputs(1) =struct('name', '', 'datatype', '', 'original_name', '');
    for i=1:numel(inputList)
        found = true;
        
        if ismember(inputList{i}, {nodes.(node).inputs.name})
            blk_inputs(i) = nodes.(node).inputs(...
                ismember( {nodes.(node).inputs.name}, inputList{i}));
        elseif ismember(inputList{i}, {nodes.(node).outputs.name})
            blk_inputs(i) = nodes.(node).outputs(...
                ismember( {nodes.(node).outputs.name}, inputList{i}));
            
        elseif ismember(inputList{i}, {nodes.(node).locals.name})
            blk_inputs(i) = nodes.(node).locals(...
                ismember( {nodes.(node).locals.name}, inputList{i}));
        else
            display_msg(['couldn''t find variable ' inputList{i} ' in EMF'], MsgType.ERROR, 'MCDC2SLX', '');
            found = false;
            blk_inputs(i) = [];
        end
        if found
            var_orig_name = originalNamesMap(inputList{i});
            block_name = ...
                XMLUtils.get_block_name_from_variable_using_xRoot(...
                mdlTraceRoot, nodes.(node).original_name, var_orig_name);
            xml_trace.add_Input(var_orig_name, block_name, 1, 1);
        end
    end
    [x2, y2] = Lus2SLXUtils.process_inputs(node_block_path, blk_inputs, '', x2, y2);
    
    
    
    % Instructions
    %deal with the invariant expressions for the cocospec Subsys,
    blk_exprs = {};
    for i=1:numel(instructionsIDs)
        blk_exprs.(instructionsIDs{i}) = nodes.(node).instrs.(instructionsIDs{i});
    end
    Lus2SLXUtils.instrs_process(nodes, new_model_name, node_block_path, blk_exprs, '', x2, y2, []);
    
end
end

%%
function variables_names = mcdcVariables(node_struct)
variables_names = {};
annotations = node_struct.annots;
fields = fieldnames(annotations);
for i=1:numel(fields)
    if ismember('mcdc', annotations.(fields{i}).key) ...
            && ismember('coverage', annotations.(fields{i}).key)
        variables_names{numel(variables_names) + 1} = ...
            annotations.(fields{i}).eexpr.qfexpr.value;
    end
end

end
%%
function [instructionsIDs, inputList]= get_mcdc_instructions(initial_variables_names, ...
    lhs_instrID_map, lhs_rhs_map, originalNamesMap, traceable_variables)
instructionsIDs = {};
inputList = {};
new_variables_names = {};
for i=1:numel(initial_variables_names)
    %add the current list instructions
    instructionsIDs{numel(instructionsIDs) + 1} = lhs_instrID_map(initial_variables_names{i});
    %caclulate the dependencies
    rhs_list = lhs_rhs_map(initial_variables_names{i});
    if iscell(rhs_list)
        for j=1:numel(rhs_list)
            origin_name = originalNamesMap(rhs_list{j});
            if ismember(origin_name, traceable_variables)
                inputList{numel(inputList) + 1} = rhs_list{j};
            else
                new_variables_names{numel(new_variables_names) + 1} = ...
                    rhs_list{j};
            end
        end
    else
        origin_name = originalNamesMap(rhs_list);
        if ismember(origin_name, traceable_variables)
            inputList{numel(inputList) + 1} = rhs_list;
        else
            new_variables_names{numel(new_variables_names) + 1} = ...
                rhs_list;
        end
    end
end
if ~isempty(new_variables_names)
    [instructionsIDs_2, inputList_2]= get_mcdc_instructions(new_variables_names, ...
        lhs_instrID_map, lhs_rhs_map, originalNamesMap, traceable_variables);
    instructionsIDs = [instructionsIDs, instructionsIDs_2];
    inputList = [inputList, inputList_2];
end
inputList = unique(inputList);
instructionsIDs = unique(instructionsIDs);
end
%%
function [x2, y2] = process_mcdc_outputs(node_block_path, blk_outputs, ID, x2, y2)
if ~bdIsLoaded('pp_lib'); load_system('pp_lib.slx'); end
for i=1:numel(blk_outputs)
    if y2 < 30000; y2 = y2 + 150; else x2 = x2 + 500; y2 = 100; end
    if isfield(blk_outputs(i), 'name')
        var_name = BUtils.adapt_block_name(blk_outputs(i).name, ID);
    else
        var_name = BUtils.adapt_block_name(blk_outputs(i), ID);
    end
    output_path = strcat(node_block_path,'/',var_name);
    output_input =  strcat(node_block_path,'/',var_name,'_In');
    add_block('pp_lib/MCDC_Counter',...
        output_path,...
        'Position',[(x2+200) y2 (x2+350) (y2+50)]);
    
    add_block('simulink/Signal Routing/From',...
        output_input,...
        'GotoTag',var_name,...
        'TagVisibility', 'local', ...
        'Position',[x2 y2 (x2+50) (y2+50)]);
    
    SrcBlkH = get_param(output_input,'PortHandles');
    DstBlkH = get_param(output_path, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
end
end