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
    xml_trace] = mcdc2slx(...
    json_path, ...
    mdl_trace, ...
    output_dir, ...
    new_model_name, ...
    main_node, ...
    organize_blocks)

%% Init
[coco_dir, cocospec_name, ~] = fileparts(json_path);
if ~exist('main_node', 'var') || isempty(main_node)
    onlyMainNode = false;
else
    onlyMainNode = true;
end
if ~exist('organize_blocks', 'var') || isempty(organize_blocks)
    organize_blocks = false;
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
    DOMNODE = xmlread(mdl_trace);
catch
    display_msg(...
        ['file ' cocosim_trace_file ' can not be read as xml file'],...
        MsgType.ERROR,...
        'create_emf_verif_file', '');
    return;
end
mdlTraceRoot = DOMNODE.getDocumentElement;
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
xml_trace = XML_Trace(new_model_path, trace_file_name);
xml_trace.init();
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
    node_process(new_model_name, nodes, node_name, node_block_path, mdlTraceRoot, block_pos, xml_trace);
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
            node_process(new_model_name, nodes, node{1}, node_block_path, mdlTraceRoot, block_pos, []);
            
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
    blocks_position_process( new_model_name );
end
% Write traceability informations
xml_trace.write();
configSet = getActiveConfigSet(model_handle);
set_param(configSet, 'Solver', 'FixedStepDiscrete');
save_system(model_handle,new_model_path,'OverwriteIfChangedOnDisk',true);

% open_system(model_handle);
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
%%
end
function node_process(new_model_name, nodes, node, node_block_path, mdlTraceRoot, block_pos, xml_trace)
variables_names = mcdcVariables(nodes.(node));
display_msg([num2str(numel(variables_names)) ' mc-dc conditions has been generated'...
    ' for node ' nodes.(node).original_name], MsgType.INFO, 'mcdc2slx', '');
if ~isempty(variables_names)
    
end
end
function node_process2(new_model_name, nodes, node, node_block_path, block_pos, xml_trace)
node_name = BUtils.adapt_block_name(node);
display_msg(...
    sprintf('Processing node "%s" ',node_name),...
    MsgType.INFO, 'MCDC2SLX', '');
x2 = 200;
y2= -50;

if ~isempty(xml_trace)
    xml_trace.create_Node_Element(node_block_path,  nodes.(node).original_name);
end
add_block('built-in/Subsystem', node_block_path);%,...
%             'TreatAsAtomicUnit', 'on');
set_param(node_block_path, 'Position', block_pos);


% Outputs

blk_outputs = nodes.(node).outputs;
[x2, y2] = process_outputs(node_block_path, blk_outputs, node_name, x2, y2);


% Inputs

blk_inputs = nodes.(node).inputs;
[x2, y2] = process_inputs(node_block_path, blk_inputs, node_name, x2, y2);



% Instructions
%deal with the invariant expressions for the cocospec Subsys,
blk_exprs = nodes.(node).instrs;
instrs_process(nodes, new_model_name, node_block_path, blk_exprs, node_name, x2, y2, xml_trace);

end
%%
function [x2, y2] = instrs_process(nodes, new_model_name, node_block_path, blk_exprs, node_name,  x2, y2, xml_trace)
for var = fieldnames(blk_exprs)'
    try
        switch blk_exprs.(var{1}).kind
            case 'arrow' % lhs = True -> False;
                [x2, y2] = process_arrow(node_block_path, blk_exprs, var, node_name,  x2, y2);
                
            case 'pre' % lhs = pre rhs;
                [x2, y2] = process_pre(node_block_path, blk_exprs, var, node_name, x2, y2);
                
            case 'local_assign' % lhs = rhs;
                [x2, y2] = process_local_assign(node_block_path, blk_exprs, var, node_name,  x2, y2);
                
            case 'reset' % lhs = rhs;
                [x2, y2] = process_reset(node_block_path, blk_exprs, var, node_name,  x2, y2);
                
            case 'operator'
                [x2, y2] = process_operator(node_block_path, blk_exprs, var, node_name, x2, y2);
                
            case {'statelesscall', 'statefulcall'}
                [x2, y2] = process_node_call(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace);
                
            case 'functioncall'
                [x2, y2] = process_functioncall( node_block_path, blk_exprs, var, node_name, x2, y2);
            case 'branch'
                [x2, y2] = process_branch(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace);
        end
    catch ME
        display_msg(['couldn''t translate expression ' var{1} ' to Simulink'], MsgType.ERROR, 'MCDC2SLX', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'MCDC2SLX', '');
        %         continue;
        rethrow(ME)
    end
end
end
%%
function [x2, y2] = process_outputs(node_block_path, blk_outputs, ID, x2, y2, isBranch)
if ~exist('isBranch', 'var')
    isBranch = 0;
end
for i=1:numel(blk_outputs)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end
    if isfield(blk_outputs(i), 'name')
        var_name = BUtils.adapt_block_name(blk_outputs(i).name, ID);
    else
        var_name = BUtils.adapt_block_name(blk_outputs(i), ID);
    end
    output_path = strcat(node_block_path,'/',var_name);
    output_input =  strcat(node_block_path,'/',var_name,'_In');
    add_block('simulink/Ports & Subsystems/Out1',...
        output_path,...
        'Position',[(x2+200) y2 (x2+250) (y2+50)]);
    if isBranch
        signal_cv_path = strcat(node_block_path,'/',var_name, '_copy');
        add_block('simulink/Signal Attributes/Signal Conversion',...
            signal_cv_path,...
            'Position',[(x2+100) y2 (x2+150) (y2+50)]);
        SrcBlkH = get_param(signal_cv_path,'PortHandles');
        DstBlkH = get_param(output_path, 'PortHandles');
        add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
        output_path = signal_cv_path;
    end
    
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

%%
function [x2, y2] = process_inputs(node_block_path, blk_inputs, ID, x2, y2)
for i=1:numel(blk_inputs)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end
    var_name = BUtils.adapt_block_name(blk_inputs(i).name, ID);
    inport_path = strcat(node_block_path,'/',var_name);
    inport_output =  strcat(node_block_path,'/',var_name,'_out');
    
    add_block('simulink/Ports & Subsystems/In1',...
        inport_path,...
        'Position',[x2 y2 (x2+50) (y2+50)]);
    dt = blk_inputs(i).datatype;
    if strcmp(dt, 'bool')
        set_param(inport_path, 'OutDataTypeStr', 'boolean');
    elseif strcmp(dt, 'int')
        set_param(inport_path, 'OutDataTypeStr', 'int32');
    elseif strcmp(dt, 'real')
        set_param(inport_path, 'OutDataTypeStr', 'double');
    else
        set_param(inport_path, 'OutDataTypeStr', dt);
    end
    
    %we create a GoTo block for this input
    add_block('simulink/Signal Routing/Goto',...
        inport_output,...
        'GotoTag',var_name,...
        'TagVisibility', 'local', ...
        'Position',[(x2+100) y2 (x2+150) (y2+50)]);
    
    SrcBlkH = get_param(inport_path,'PortHandles');
    DstBlkH = get_param(inport_output, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
end
end

%%
function [x2, y2] = process_arrow(node_block_path, blk_exprs, var, node_name, x2, y2)
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end
ID = BUtils.adapt_block_name(var{1});
lhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).lhs, node_name);
lhs_path = strcat(node_block_path,'/',ID, '_lhs');
init_path =  strcat(node_block_path,'/',ID,'_init');
delay_path = strcat(node_block_path,'/Arrow_',ID);

add_block('simulink/Commonly Used Blocks/Constant',...
    init_path,...
    'Value','0',...
    'OutDataTypeStr','boolean',...
    'Position',[x2 y2 (x2+50) (y2+50)]);
add_block('simulink/Discrete/Delay',...
    delay_path,...
    'InitialCondition','1',...
    'DelayLength','1',...
    'Position',[(x2+100) y2 (x2+150) (y2+50)]);
add_block('simulink/Signal Routing/Goto',...
    lhs_path,...
    'GotoTag',lhs_name,...
    'TagVisibility', 'local', ...
    'Position',[(x2+200) y2 (x2+250) (y2+50)]);

SrcBlkH = get_param(init_path,'PortHandles');
DstBlkH = get_param(delay_path, 'PortHandles');
add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');

SrcBlkH = get_param(delay_path,'PortHandles');
DstBlkH = get_param(lhs_path, 'PortHandles');
add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');

end

%%
function [x2, y2] = process_pre(node_block_path, blk_exprs, var, node_name, x2, y2)
% lhs = pre rhs;
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end

ID = BUtils.adapt_block_name(var{1});
lhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).lhs, node_name);
rhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).rhs.value, node_name);
lhs_path = strcat(node_block_path,'/',ID, '_lhs');
rhs_path =  strcat(node_block_path,'/',ID,'_rhs');
delay_path = strcat(node_block_path,'/PRE_',ID);

rhs_type = blk_exprs.(var{1}).rhs.type;
if strcmp(rhs_type, 'constant')
    rhs_name = blk_exprs.(var{1}).rhs.value;
    add_block('simulink/Commonly Used Blocks/Constant',...
        rhs_path,...
        'Value',rhs_name,...
        'Position',[x2 y2 (x2+50) (y2+50)]);
    %     set_param(rhs_path, 'OutDataTypeStr','Inherit: Inherit via back propagation');
    dt = blk_exprs.(var{1}).rhs.datatype;
    if strcmp(dt, 'bool')
        set_param(rhs_path, 'OutDataTypeStr', 'boolean');
    elseif strcmp(dt, 'int')
        set_param(rhs_path, 'OutDataTypeStr', 'int32');
    elseif strcmp(dt, 'real')
        set_param(rhs_path, 'OutDataTypeStr', 'double');
    else
        set_param(rhs_path, 'OutDataTypeStr', dt);
    end
else
    add_block('simulink/Signal Routing/From',...
        rhs_path,...
        'GotoTag', rhs_name,...
        'TagVisibility', 'local', ...
        'Position',[x2 y2 (x2+50) (y2+50)]);
end
add_block('simulink/Discrete/Delay',...
    delay_path,...
    'InitialCondition','0',...
    'DelayLength','1',...
    'Position',[(x2+100) y2 (x2+150) (y2+50)]);

add_block('simulink/Signal Routing/Goto',...
    lhs_path,...
    'GotoTag',lhs_name,...
    'TagVisibility', 'local', ...
    'Position',[(x2+200) y2 (x2+250) (y2+50)]);

SrcBlkH = get_param(rhs_path, 'PortHandles');
DstBlkH = get_param(delay_path, 'PortHandles');
add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');

SrcBlkH = get_param(delay_path,'PortHandles');
DstBlkH = get_param(lhs_path, 'PortHandles');
add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');

end

%%
function  [x2, y2] = process_local_assign(node_block_path, blk_exprs, var, node_name, x2, y2)
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;

ID = BUtils.adapt_block_name(var{1});
lhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).lhs, node_name);
rhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).rhs.value, node_name);
lhs_path = BUtils.get_unique_name(strcat(node_block_path,'/',ID, '_lhs'));
rhs_path = BUtils.get_unique_name(strcat(node_block_path,'/',ID,'_rhs'));

rhs_type = blk_exprs.(var{1}).rhs.type;
if strcmp(rhs_type, 'constant')
    rhs_name = blk_exprs.(var{1}).rhs.value;
    add_block('simulink/Commonly Used Blocks/Constant',...
        rhs_path,...
        'Value',rhs_name,...
        'Position',[x2 y2 (x2+50) (y2+50)]);
    dt = blk_exprs.(var{1}).rhs.datatype;
    if strcmp(dt, 'bool')
        set_param(rhs_path, 'OutDataTypeStr', 'boolean');
    elseif strcmp(dt, 'int')
        set_param(rhs_path, 'OutDataTypeStr', 'int32');
    elseif strcmp(dt, 'real')
        set_param(rhs_path, 'OutDataTypeStr', 'double');
    else
        set_param(rhs_path, 'OutDataTypeStr', dt);
    end
else
    add_block('simulink/Signal Routing/From',...
        rhs_path,...
        'GotoTag',rhs_name,...
        'TagVisibility', 'local', ...
        'Position',[x2 y2 (x2+50) (y2+50)]);
end
add_block('simulink/Signal Routing/Goto',...
    lhs_path,...
    'GotoTag',lhs_name,...
    'TagVisibility', 'local', ...
    'Position',[(x2+100) y2 (x2+150) (y2+50)]);

SrcBlkH = get_param(rhs_path,'PortHandles');
DstBlkH = get_param(lhs_path, 'PortHandles');
add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
end

%%
function  [x2, y2] = process_reset(node_block_path, blk_exprs, var, node_name, x2, y2)
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end

ID = BUtils.adapt_block_name(var{1});
lhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).lhs, node_name);
lhs_path = BUtils.get_unique_name(strcat(node_block_path,'/',ID, '_lhs'));
rhs_path = BUtils.get_unique_name(strcat(node_block_path,'/',ID,'_rhs'));


rhs_name = blk_exprs.(var{1}).rhs;
add_block('simulink/Commonly Used Blocks/Constant',...
    rhs_path,...
    'Value',rhs_name,...
    'Position',[x2 y2 (x2+50) (y2+50)]);
set_param(rhs_path, 'OutDataTypeStr', 'boolean');


add_block('simulink/Signal Routing/Goto',...
    lhs_path,...
    'GotoTag',lhs_name,...
    'TagVisibility', 'local', ...
    'Position',[(x2+100) y2 (x2+150) (y2+50)]);

SrcBlkH = get_param(rhs_path,'PortHandles');
DstBlkH = get_param(lhs_path, 'PortHandles');
add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
end
%%
function [x2, y2] = process_operator(node_block_path, blk_exprs, var, node_name, x2, y2)
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;

ID = BUtils.adapt_block_name(var{1});
lhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).lhs, node_name);
lhs_path = strcat(node_block_path,'/',ID, '_lhs');
op_path = strcat(node_block_path,'/',ID,'_operator');
operator = blk_exprs.(var{1}).name;

dt = blk_exprs.(var{1}).args(1).datatype;
if strcmp(dt, 'bool')
    dt =  'boolean';
elseif strcmp(dt, 'int')
    dt =  'int32';
elseif strcmp(dt, 'real')
    dt =  'double';
end
add_operator_block(op_path, operator,x2 ,y2, dt);

add_block('simulink/Signal Routing/Goto',...
    lhs_path,...
    'GotoTag',lhs_name,...
    'TagVisibility', 'local', ...
    'Position',[(x2+300) y2 (x2+350) (y2+50)]);
SrcBlkH = get_param(op_path,'PortHandles');
DstBlkH = get_param(lhs_path, 'PortHandles');
add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');

DstBlkH = get_param(op_path,'PortHandles');
for inport_number=1:numel(blk_exprs.(var{1}).args)
    local_var = blk_exprs.(var{1}).args(inport_number).value;
    local_var_adapted = BUtils.adapt_block_name(local_var, node_name);
    input_path = strcat(node_block_path,'/',ID,'_rhs_',num2str(inport_number));
    if strcmp(blk_exprs.(var{1}).args(inport_number).type, 'constant')
        add_block('simulink/Commonly Used Blocks/Constant',...
            input_path,...
            'Value', local_var,...
            'Position',[x2 y2 (x2+50) (y2+50)]);
        %         set_param(input_path, 'OutDataTypeStr','Inherit: Inherit via back propagation');
        dt = blk_exprs.(var{1}).args(inport_number).datatype;
        if strcmp(dt, 'bool')
            set_param(input_path, 'OutDataTypeStr', 'boolean');
        elseif strcmp(dt, 'int')
            set_param(input_path, 'OutDataTypeStr', 'int32');
        elseif strcmp(dt, 'real')
            set_param(input_path, 'OutDataTypeStr', 'double');
        else
            set_param(input_path, 'OutDataTypeStr', dt);
        end
    else
        add_block('simulink/Signal Routing/From',...
            input_path,...
            'GotoTag',local_var_adapted,...
            'TagVisibility', 'local', ...
            'Position',[x2 y2 (x2+50) (y2+50)]);
    end
    y2 = y2 + 150;
    SrcBlkH = get_param(input_path,'PortHandles');
    
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(inport_number), 'autorouting', 'on');
end

end

function add_operator_block(op_path, operator, x, y2, dt)
switch operator
    case {'+', '-'}
        operator = regexprep(operator,'+','++');
        operator = regexprep(operator,'-','+-');
        add_block('simulink/Math Operations/Add',...
            op_path,...
            'Inputs', operator, ...
            'OutDataTypeStr', dt, ...
            'Position',[(x+200) y2 (x+250) (y2+50)]);
    case 'uminus'
        add_block('simulink/Math Operations/Gain',...
            op_path,...
            'Gain', '-1', ...
            'OutDataTypeStr', dt, ...
            'Position',[(x+200) y2 (x+250) (y2+50)]);
    case '*'
        add_block('simulink/Math Operations/Product',...
            op_path,...
            'OutDataTypeStr', dt, ...
            'Position',[(x+200) y2 (x+250) (y2+50)]);
    case '/'
        add_block('simulink/Math Operations/Divide',...
            op_path,...
            'OutDataTypeStr', dt, ...
            'Position',[(x+200) y2 (x+250) (y2+50)]);
    case 'mod'
        add_block('simulink/Math Operations/Math Function',...
            op_path,...
            'Operator', 'rem',...
            'OutDataTypeStr', dt, ...
            'Position',[(x+200) y2 (x+250) (y2+50)]);
    case {'&&', '||', 'xor', 'not'}
        operator = regexprep(operator,'&&','AND');
        operator = regexprep(operator,'||','OR');
        operator = regexprep(operator,'xor','XOR');
        operator = regexprep(operator,'not','NOT');
        add_block('simulink/Logic and Bit Operations/Logical Operator',...
            op_path,...
            'Operator', operator,...
            'Position',[(x+200) y2 (x+250) (y2+50)]);
        
        
    case {'=', '!=', '<','<=', '>=', '>'}
        if strcmp(operator, '='); operator = regexprep(operator,'=','=='); end
        operator = regexprep(operator,'!=','~=');
        operator = regexprep(operator,'<>','~=');
        add_block('simulink/Logic and Bit Operations/Relational Operator',...
            op_path,...
            'Operator', operator,...
            'Position',[(x+200) y2 (x+250) (y2+50)]);
        
    case 'impl'
        load_system('cocosimLibs.slx');
        add_block('cocosimLibs/Implication',...
            op_path,...
            'Position',[(x+200) y2 (x+250) (y2+50)]);
    otherwise
        display_msg(['Unkown operator ' operator], MsgType.ERROR, 'MCDC2SLX', '');
end

end

%%

function  [x2, y2] = process_node_call(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace)
persistent calls_map;
if isempty(calls_map)
    calls_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
end
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end

ID = BUtils.adapt_block_name(blk_exprs.(var{1}).name);
fcn_path = BUtils.get_unique_name(...
    strcat(node_block_path,'/',ID,'_call'));
if ~isempty(xml_trace)

    block_pos = [(x2+100) y2 (x2+250) (y2+50)];
    if isKey(calls_map, ID) && (getSimulinkBlockHandle(calls_map(ID)) ~= -1)
        fcn_subsys = calls_map(ID);
        add_block(fcn_subsys,...
            fcn_path,...
            'Position',block_pos);
    else
        node_process(new_model_name, nodes, blk_exprs.(var{1}).name, fcn_path, block_pos, xml_trace);
        calls_map(ID) = fcn_path;
    end
else
    fcn_subsys = strcat(new_model_name, '/', ID);
    add_block(fcn_subsys,...
        fcn_path,...
        'Position',[(x2+100) y2 (x2+250) (y2+50)]);
    
end
if strcmp(blk_exprs.(var{1}).kind, 'statefulcall') && strcmp(blk_exprs.(var{1}).reset.resetable, 'true')
    add_block('simulink/Ports & Subsystems/Resettable Subsystem/Reset', ...
        fullfile(fcn_path, 'Reset'),...
        'ResetTriggerType', 'level hold');
    reset_name = blk_exprs.(var{1}).reset.name;
    reset_adapted = BUtils.adapt_block_name(reset_name, node_name);
    reset_path =  BUtils.get_unique_name(...
        strcat(node_block_path,'/',ID,'_reset'));
    add_block('simulink/Signal Routing/From',...
        reset_path,...
        'GotoTag',reset_adapted,...
        'TagVisibility', 'local', ...
        'Position',[(x2+150) (y2-50) (x2+200) (y2-30)]);
    SrcBlkH = get_param(reset_path, 'PortHandles');
    DstBlkH = get_param(fcn_path,'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Reset(1), 'autorouting', 'on');
end
SrcBlkH = get_param(fcn_path,'PortHandles');
y3=y2;
for i=1:numel(blk_exprs.(var{1}).lhs)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end
    output = blk_exprs.(var{1}).lhs(i);
    output_adapted = BUtils.adapt_block_name(output, node_name);
    output_path = BUtils.get_unique_name(...
        strcat(node_block_path,'/',ID,'_out',num2str(i)));
    add_block('simulink/Signal Routing/Goto',...
        output_path,...
        'GotoTag',output_adapted,...
        'TagVisibility', 'local', ...
        'Position',[(x2+300) y2 (x2+350) (y2+50)]);
    DstBlkH = get_param(output_path, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
    y2 = y2 + 150;
end
y2 = y3;
DstBlkH = get_param(fcn_path,'PortHandles');
for i=1:numel(blk_exprs.(var{1}).args)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end
    input = blk_exprs.(var{1}).args(i).value;
    input_type = blk_exprs.(var{1}).args(i).type;
    input_adapted = BUtils.adapt_block_name(input, node_name);
    input_path = BUtils.get_unique_name(...
        strcat(node_block_path,'/',ID,'_In',num2str(i)));
    if strcmp(input_type, 'constant')
        add_block('simulink/Commonly Used Blocks/Constant',...
            input_path,...
            'Value', input,...
            'Position',[x2 y2 (x2+50) (y2+50)]);
        %         set_param(input_path, 'OutDataTypeStr','Inherit: Inherit via back propagation');
        dt = blk_exprs.(var{1}).args(i).datatype;
        if strcmp(dt, 'bool')
            set_param(input_path, 'OutDataTypeStr', 'boolean');
        elseif strcmp(dt, 'int')
            set_param(input_path, 'OutDataTypeStr', 'int32');
        elseif strcmp(dt, 'real')
            set_param(input_path, 'OutDataTypeStr', 'double');
        else
            set_param(input_path, 'OutDataTypeStr', dt);
        end
    else
        add_block('simulink/Signal Routing/From',...
            input_path,...
            'GotoTag',input_adapted,...
            'TagVisibility', 'local', ...
            'Position',[x2 y2 (x2+50) (y2+50)]);
    end
    y2 = y2 + 150;
    SrcBlkH = get_param(input_path,'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(i), 'autorouting', 'on');
end
end


%%
function [x2, y2] = link_subsys_inputs( parent_path, subsys_block_path, inputs, var, node_name, x2, y2)
[~, ID, ~] = fileparts(subsys_block_path);%BUtils.adapt_block_name(var{1});
DstBlkH = get_param(subsys_block_path,'PortHandles');
for i=1:numel(inputs)
    input = inputs(i).name;
    input_adapted = BUtils.adapt_block_name(input, node_name);
    input_path = BUtils.get_unique_name(...
        strcat(parent_path,'/',ID,'_In',num2str(i)));
    add_block('simulink/Signal Routing/From',...
        input_path,...
        'GotoTag',input_adapted,...
        'TagVisibility', 'local', ...
        'Position',[x2 y2 (x2+50) (y2+50)]);
    y2 = y2 + 150;
    SrcBlkH = get_param(input_path,'PortHandles');
    add_line(parent_path, SrcBlkH.Outport(1), DstBlkH.Inport(i), 'autorouting', 'on');
end
end
function [x2, y2] = link_subsys_outputs( parent_path, subsys_block_path, outputs, var,node_name,  x2, y2, isBranch, branchIdx)
[~, ID, ~] = fileparts(subsys_block_path);%BUtils.adapt_block_name(var{1});
SrcBlkH = get_param(subsys_block_path,'PortHandles');
for i=1:numel(outputs)
    output = outputs(i);
    output_adapted = BUtils.adapt_block_name(output,node_name);
    if exist('isBranch','var') && isBranch
        output_adapted = strcat(output_adapted, '_branch_', num2str(branchIdx));
    end
    output_path = strcat(parent_path,'/',ID,'_out',num2str(i));
    add_block('simulink/Signal Routing/Goto',...
        output_path,...
        'GotoTag',output_adapted,...
        'TagVisibility', 'local', ...
        'Position',[(x2+300) y2 (x2+350) (y2+50)]);
    y2 = y2 + 150;
    DstBlkH = get_param(output_path, 'PortHandles');
    add_line(parent_path, SrcBlkH.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
end
end
%%
function [x2, y2] = process_branch(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace)
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;

ID = BUtils.adapt_block_name(var{1});
branch_block_path = fullfile(node_block_path, ID);
add_block('built-in/Subsystem', branch_block_path,...
    'Position',[(x2+200) y2 (x2+250) (y2+50)]);
%    'TreatAsAtomicUnit', 'on', ...


x3 = 50;
y3 = 50;

%% Outputs
blk_outputs = blk_exprs.(var{1}).outputs;
[x3, y3] = process_outputs(branch_block_path, blk_outputs, ID, x3, y3);

%% Inputs
blk_inputs = blk_exprs.(var{1}).inputs;
[x3, y3] = process_inputs(branch_block_path, blk_inputs, ID, x3, y3);

%% link outputs from outside
outputs = blk_exprs.(var{1}).outputs;
[x2, y4] =link_subsys_outputs( node_block_path, branch_block_path, outputs, var, node_name, x2, y2);


%% link inputs from outside
inputs = blk_exprs.(var{1}).inputs;
[x2, y5] = link_subsys_inputs( node_block_path, branch_block_path, inputs, var, node_name, x2, y2);

y2 = max(y4, y5);

%% add IF block with IF expressions
IF_path = strcat(branch_block_path,'/',ID,'_IF');
branches = blk_exprs.(var{1}).branches;
branches_names = {};
i = 1;
for b=fieldnames(branches)'
    branches_names{i} = branches.(b{1}).guard_value;
    i = i+1;
end
% fields expressed as Numbers in Json are translated to xNumber (12 -> x12)
% I try here to delete the x in this case.
% branches_names_adapted = regexprep(branches_names, '^x(\d+[\.]?\d*)$', '$1');

%adapt IF expression to the form u==exp.
[n, m] = size(branches_names);
prefix = cell(n,m);
prefix(:,:) = {'u1 == '};
ifexp = cellfun(@(x,y) [x  y], prefix, branches_names,'un',0);
ifexp = regexprep(ifexp, 'u1 == true', 'u1');
ifexp = regexprep(ifexp, 'u1 == false', '~u1');
IfExpression = ifexp{1};
if numel(ifexp) > 1
    ElseIfExpressions = strjoin(ifexp(2:end), ', ');
else
    ElseIfExpressions = '';
end

y3 = y3 + 150;
add_block('simulink/Ports & Subsystems/If',...
    IF_path,...
    'IfExpression', IfExpression, ...
    'ElseIfExpressions', ElseIfExpressions, ...
    'ShowElse', 'off', ...
    'Position',[(x3+100) y3 (x3+150) (y3+50)]);

%% add Guard input
guard_path = strcat(branch_block_path,'/',ID,'_guard');
guard = blk_exprs.(var{1}).guard.value;
guard_type = blk_exprs.(var{1}).guard.type;
guard_adapted = BUtils.adapt_block_name(guard, ID);
if strcmp(guard_type, 'constant')
    add_block('simulink/Commonly Used Blocks/Constant',...
        guard_path,...
        'Value', guard,...
        'Position',[x3 y3 (x3+50) (y3+50)]);
    %     set_param(guard_path, 'OutDataTypeStr','Inherit: Inherit via back propagation');
    dt = blk_exprs.(var{1}).guard.datatype;
    if strcmp(dt, 'bool')
        set_param(guard_path, 'OutDataTypeStr', 'boolean');
    elseif strcmp(dt, 'int')
        set_param(guard_path, 'OutDataTypeStr', 'int32');
    elseif strcmp(dt, 'real')
        set_param(guard_path, 'OutDataTypeStr', 'double');
    else
        set_param(guard_path, 'OutDataTypeStr', dt);
    end
else
    add_block('simulink/Signal Routing/From',...
        guard_path,...
        'GotoTag',guard_adapted,...
        'TagVisibility', 'local', ...
        'Position',[x3 y3 (x3+50) (y3+50)]);
end
%% link guard to IF block
DstBlkH = get_param(IF_path,'PortHandles');
SrcBlkH = get_param(guard_path,'PortHandles');
add_line(branch_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
y3 = y3 + 150;
x3 = x3 + 300;
%% branches
idx = 1;
for b=fieldnames(branches)'
    branch_ID = strcat(ID,'_branch_',branches.(b{1}).guard_value);
    branch_path = strcat(branch_block_path,'/',branch_ID);
    add_block('simulink/Ports & Subsystems/If Action Subsystem',...
        branch_path,...
        'Position',[(x3+100) y3 (x3+150) (y3+50)]);
    delete_line(branch_path, 'In1/1', 'Out1/1');
    delete_block(strcat(branch_path,'/In1'));
    delete_block(strcat(branch_path,'/Out1'));
    
    % link IF with Action subsystem
    DstBlkH = get_param(branch_path,'PortHandles');
    SrcBlkH = get_param(IF_path,'PortHandles');
    add_line(branch_block_path, SrcBlkH.Outport(idx), DstBlkH.Ifaction(1), 'autorouting', 'on');
    
    % link Sction subsys inputs
    % Outputs
    x4 = 50;
    y4 = 50;
    blk_outputs = blk_exprs.(var{1}).outputs;
    [x4, y4] = process_outputs(branch_path, blk_outputs, branch_ID, x4, y4, true);
    
    % Inputs
    blk_inputs = branches.(b{1}).inputs;
    [x4, y4] = process_inputs(branch_path, blk_inputs, branch_ID, x4, y4);
    [x3, y3] = link_subsys_inputs( branch_block_path, branch_path, blk_inputs, b, ID, x3, y3);
    
    
    % instructions
    branch_exprs = branches.(b{1}).instrs;
    [x4, y4] = instrs_process(nodes, new_model_name, branch_path, branch_exprs, branch_ID, x4, y4, xml_trace);
    
    %
    idx = idx + 1;
    y3 = y3 + 150;
end

%% Merge outputs
outputs = blk_exprs.(var{1}).outputs;
for i=1:numel(outputs)
    output = outputs(i);
    output_adapted = BUtils.adapt_block_name(output, ID);
    merge_path = strcat(branch_block_path,'/',output_adapted,'_merge');
    output_path = strcat(branch_block_path,'/',output_adapted,'_merged');
    nb_merge = numel(fieldnames(branches));
    add_block('simulink/Signal Routing/Goto',...
        output_path,...
        'GotoTag',output_adapted,...
        'TagVisibility', 'local', ...
        'Position',[(x3+300) y3 (x3+350) (y3+50)]);
    if nb_merge==1
        DstBlkH = get_param(output_path, 'PortHandles');
    else
        add_block('simulink/Signal Routing/Merge',...
            merge_path,...
            'Inputs', num2str(numel(fieldnames(branches))),...
            'Position',[(x3+200) y3 (x3+250) (y3+50)]);
        % Merge output
        SrcBlkH = get_param(merge_path, 'PortHandles');
        DstBlkH = get_param(output_path, 'PortHandles');
        add_line(branch_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
        % Merge inputs
        DstBlkH = get_param(merge_path, 'PortHandles');
    end
    
    
    
    j = 1;
    for b=fieldnames(branches)'
        branch_path = strcat(branch_block_path,'/',ID,'_branch_',branches.(b{1}).guard_value);
        SrcBlkH = get_param(branch_path,'PortHandles');
        add_line(branch_block_path, SrcBlkH.Outport(i), DstBlkH.Inport(j), 'autorouting', 'on');
        j = j + 1;
    end
    
    y3 = y3 + 150;
end
end


%%
function  [x2, y2] = process_functioncall(node_block_path, blk_exprs, var, node_name, x2, y2)
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end

ID = BUtils.adapt_block_name(var{1});
fcn_path = strcat(node_block_path,'/',ID,'_call');
fun_name = BUtils.adapt_block_name(blk_exprs.(var{1}).name);
fun_library = blk_exprs.(var{1}).library;

status = add_funLibrary_path(fcn_path, fun_name, fun_library, [(x2+100) y2 (x2+250) (y2+50)]);
if status
    return;
end

SrcBlkH = get_param(fcn_path,'PortHandles');
y3=y2;
for i=1:numel(blk_exprs.(var{1}).lhs)
    output = blk_exprs.(var{1}).lhs(i);
    output_adapted = BUtils.adapt_block_name(output, node_name);
    output_path = BUtils.get_unique_name(...
        strcat(node_block_path,'/',ID,'_out', num2str(i)));
    add_block('simulink/Signal Routing/Goto',...
        output_path,...
        'GotoTag',output_adapted,...
        'TagVisibility', 'local', ...
        'Position',[(x2+300) y2 (x2+350) (y2+50)]);
    DstBlkH = get_param(output_path, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
    y2 = y2 + 150;
end
y2 = y3;
DstBlkH = get_param(fcn_path,'PortHandles');
for i=1:numel(blk_exprs.(var{1}).args)
    input = blk_exprs.(var{1}).args(i).value;
    input_type = blk_exprs.(var{1}).args(i).type;
    input_adapted = BUtils.adapt_block_name(input, node_name);
    input_path = BUtils.get_unique_name(...
        strcat(node_block_path,'/',ID,'_In',num2str(i)));
    if strcmp(input_type, 'constant')
        add_block('simulink/Commonly Used Blocks/Constant',...
            input_path,...
            'Value', input,...
            'Position',[x2 y2 (x2+50) (y2+50)]);
        %         set_param(input_path, 'OutDataTypeStr','Inherit: Inherit via back propagation');
        dt = blk_exprs.(var{1}).args(i).datatype;
        if strcmp(dt, 'bool')
            set_param(input_path, 'OutDataTypeStr', 'boolean');
        elseif strcmp(dt, 'int')
            set_param(input_path, 'OutDataTypeStr', 'int32');
        elseif strcmp(dt, 'real')
            set_param(input_path, 'OutDataTypeStr', 'double');
        else
            set_param(input_path, 'OutDataTypeStr', dt);
        end
    else
        add_block('simulink/Signal Routing/From',...
            input_path,...
            'GotoTag',input_adapted,...
            'TagVisibility', 'local', ...
            'Position',[x2 y2 (x2+50) (y2+50)]);
    end
    y2 = y2 + 150;
    SrcBlkH = get_param(input_path,'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(i), 'autorouting', 'on');
end
end


function status = add_funLibrary_path(dst_path, fun_name, fun_library, position)
status = 0;
if strcmp(fun_library, 'lustrec_math') || strcmp(fun_library, 'math')
    function_name = fun_name;
    fcn_path = 'simulink/Math Operations/Trigonometric Function';
    needFunctionParam = true;
    if strcmp(fun_name, 'cbrt')
    elseif strcmp(fun_name, 'ceil')
        fcn_path = 'simulink/Math Operations/Rounding Function';
    elseif strcmp(fun_name, 'fabs')
        needFunctionParam = false;
        fcn_path = 'simulink/Math Operations/Abs';
    elseif strcmp(fun_name, 'pow')
        fcn_path = 'simulink/Math Operations/Math Function';
    elseif strcmp(fun_name, 'sqrt')
        needFunctionParam = false;
        fcn_path = 'simulink/Math Operations/Sqrt';
    end
    if needFunctionParam
        add_block(fcn_path,...
            dst_path,...
            'Function', function_name,...
            'Position',position);
    else
        add_block(fcn_path,...
            dst_path,...
            'Position',position);
    end
elseif strcmp(fun_library, 'conv')
    fcn_path = 'simulink/Signal Attributes/Data Type Conversion';
    dt = 'double';
    if strcmp(fun_name, 'real_to_int')
        dt = 'int32';
    end
    add_block(fcn_path,...
            dst_path,...
            'OutDataTypeStr', dt,...
            'Position',position);
    
else
    status = 1;
end
end
