function new_name = lus2slx(contract_path, output_dir)
%LUS2SLX translate an EMF file to Simulink blocks. Every node is translated
%to a subsystem.


%%
[coco_dir, cocospec_name, ~] = fileparts(contract_path);
if nargin < 2
    output_dir = coco_dir;
end

data = BUtils.read_EMF(contract_path);

trace_file_name = fullfile(output_dir, strcat(cocospec_name, '.emf.trace.xml'));
xml_trace = XML_Trace(contract_path, trace_file_name);
xml_trace.init();
%%

base_name = regexp(cocospec_name,'\.','split');
new_model_name = BUtils.adapt_block_name(strcat(base_name{1}, '_emf'));
new_name = fullfile(output_dir,strcat(new_model_name,'.slx'));
if exist(new_name,'file')
    if bdIsLoaded(new_model_name)
        close_system(new_model_name,0)
    end
    delete(new_name);
end
close_system(new_model_name,0);
model_handle = new_system(new_model_name);
% save_system(model_handle,new_name);

x = 200;
y = -50;

nodes = data.nodes;
for node = fieldnames(nodes)'
    try
        
        y = y + 150;
        x2 = 200;
        y2= -50;
        node_name = BUtils.adapt_block_name(node{1});
        node_block_path = fullfile(new_model_name,node_name);
        xml_trace.create_Node_Element(node_block_path, node{1});
        add_block('built-in/Subsystem', node_block_path);%,...
        %             'TreatAsAtomicUnit', 'on');
        block_pos = [(x+100) y (x+250) (y+50)];
        set_param(node_block_path, 'Position', block_pos);
        
        
        %% Outputs
        
        blk_outputs = nodes.(node{1}).outputs;
        [x2, y2] = process_outputs(node_block_path, blk_outputs, node_name, x2, y2);
        
        
        %% Inputs
        
        blk_inputs = nodes.(node{1}).inputs;
        [x2, y2] = process_inputs(node_block_path, blk_inputs, node_name, x2, y2);
        
        
        
        %% Instructions
        %deal with the invariant expressions for the cocospec Subsys,
        blk_exprs = nodes.(node{1}).instrs;
        [x2, y2] = instrs_process(new_model_name, node_block_path, blk_exprs, node_name, x2, y2, xml_trace);
        
    catch ME
        display_msg(['couldn''t translate node ' node{1} ' to Simulink'], MsgType.ERROR, 'LUS2SLX', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'LUS2SLX', '');
        %         continue;
        rethrow(ME);
    end
end

% Write traceability informations
xml_trace.write();
configSet = getActiveConfigSet(model_handle);
set_param(configSet, 'Solver', 'FixedStepDiscrete');
save_system(model_handle,new_name,'OverwriteIfChangedOnDisk',true);
% open_system(model_handle);
end

%%
function [x2, y2] = instrs_process(new_model_name, node_block_path, blk_exprs, node_name,  x2, y2, xml_trace)
for var = fieldnames(blk_exprs)'
    try
        switch blk_exprs.(var{1}).kind
            case 'arrow' % lhs = False -> True;
                [x2, y2] = process_arrow(node_block_path, blk_exprs, var, node_name,  x2, y2);
                
            case 'pre' % lhs = pre rhs;
                [x2, y2] = process_pre(node_block_path, blk_exprs, var, node_name, x2, y2);
                
            case 'local_assign' % lhs = rhs;
                [x2, y2] = process_local_assign(node_block_path, blk_exprs, var, node_name,  x2, y2);
                
            case 'operator'
                [x2, y2] = process_operator(node_block_path, blk_exprs, var, node_name, x2, y2);
                
            case {'statelesscall', 'statefulcall'}
                [x2, y2] = process_node_call(new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace);
                
            case 'branch'
                [x2, y2] = process_branch(new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2);
        end
    catch ME
        display_msg(['couldn''t translate expression ' var{1} ' to Simulink'], MsgType.ERROR, 'LUS2SLX', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'LUS2SLX', '');
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
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;
    if isfield(blk_outputs(i), 'name')
        var_name = BUtils.adapt_block_name(blk_outputs(i).name, ID);
    else
        var_name = BUtils.adapt_block_name(blk_outputs(i), ID);
    end
    output_path = strcat(node_block_path,'/',var_name);
    output_input =  strcat(node_block_path,'/',var_name,'_input');
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
        'Position',[x2 y2 (x2+50) (y2+50)]);
    
    SrcBlkH = get_param(output_input,'PortHandles');
    DstBlkH = get_param(output_path, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
end
end

%%
function [x2, y2] = process_inputs(node_block_path, blk_inputs, ID, x2, y2)
for i=1:numel(blk_inputs)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;
    var_name = BUtils.adapt_block_name(blk_inputs(i).name, ID);
    inport_path = strcat(node_block_path,'/',var_name);
    inport_output =  strcat(node_block_path,'/',var_name,'_output');
    
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
        'Position',[(x2+100) y2 (x2+150) (y2+50)]);
    
    SrcBlkH = get_param(inport_path,'PortHandles');
    DstBlkH = get_param(inport_output, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
end
end

%%
function [x2, y2] = process_arrow(node_block_path, blk_exprs, var, node_name, x2, y2)
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;
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
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;

ID = BUtils.adapt_block_name(var{1});
lhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).lhs, node_name);
rhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).rhs.value, node_name);
lhs_path = strcat(node_block_path,'/',ID, '_lhs');
rhs_path =  strcat(node_block_path,'/',ID,'_rhs');
delay_path = strcat(node_block_path,'/PRE_',ID);

rhs_type = blk_exprs.(var{1}).rhs.type;
if strcmp(rhs_type, 'constant')
    rhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).rhs.value);
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
    rhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).rhs.value);
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
        'Position',[x2 y2 (x2+50) (y2+50)]);
end
add_block('simulink/Signal Routing/Goto',...
    lhs_path,...
    'GotoTag',lhs_name,...
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
        display_msg(['Unkown operator ' operator], MsgType.ERROR, 'LUS2SLX', '');
end

end

%%

function  [x2, y2] = process_node_call(new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace)
if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;

ID = BUtils.adapt_block_name(var{1});
fcn_path = strcat(node_block_path,'/',ID,'_call');
fun_name = BUtils.adapt_block_name(blk_exprs.(var{1}).name);

fcn_subsys = strcat(new_model_name, '/', fun_name);
add_block(fcn_subsys,...
    fcn_path,...
    'Position',[(x2+100) y2 (x2+250) (y2+50)]);
xml_trace.create_Node_Element(fcn_path, fun_name);

if strcmp(blk_exprs.(var{1}).kind, 'statefulcall') && strcmp(blk_exprs.(var{1}).reset.resetable, 'true')
    add_block('simulink/Ports & Subsystems/Resettable Subsystem/Reset', ...
        fullfile(fcn_path, 'Reset'),...
        'ResetTriggerType', 'level hold');
    reset_name = blk_exprs.(var{1}).reset.name;
    reset_adapted = BUtils.adapt_block_name(reset_name, node_name);
    reset_path = strcat(node_block_path,'/',ID,'_', reset_adapted);
    add_block('simulink/Signal Routing/From',...
        reset_path,...
        'GotoTag',reset_adapted,...
        'Position',[(x2+150) (y2-50) (x2+200) (y2-30)]);
    SrcBlkH = get_param(reset_path, 'PortHandles');
    DstBlkH = get_param(fcn_path,'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Reset(1), 'autorouting', 'on');
end
SrcBlkH = get_param(fcn_path,'PortHandles');
y3=y2;
for i=1:numel(blk_exprs.(var{1}).lhs)
    output = blk_exprs.(var{1}).lhs(i);
    output_adapted = BUtils.adapt_block_name(output, node_name);
    output_path = strcat(node_block_path,'/',ID,'_output_',output_adapted);
    add_block('simulink/Signal Routing/Goto',...
        output_path,...
        'GotoTag',output_adapted,...
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
    input_path = BUtils.get_unique_name(strcat(node_block_path,'/',ID,'_input_',input_adapted));
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
            'Position',[x2 y2 (x2+50) (y2+50)]);
    end
    y2 = y2 + 150;
    SrcBlkH = get_param(input_path,'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(i), 'autorouting', 'on');
end
end

%%
function [x2, y2] = link_subsys_inputs( parent_path, subsys_block_path, inputs, var, node_name, x2, y2)
ID = BUtils.adapt_block_name(var{1});
DstBlkH = get_param(subsys_block_path,'PortHandles');
for i=1:numel(inputs)
    input = inputs(i).name;
    input_adapted = BUtils.adapt_block_name(input, node_name);
    input_path = strcat(parent_path,'/',ID,'_input_',input_adapted);
    add_block('simulink/Signal Routing/From',...
        input_path,...
        'GotoTag',input_adapted,...
        'Position',[x2 y2 (x2+50) (y2+50)]);
    y2 = y2 + 150;
    SrcBlkH = get_param(input_path,'PortHandles');
    add_line(parent_path, SrcBlkH.Outport(1), DstBlkH.Inport(i), 'autorouting', 'on');
end
end
function [x2, y2] = link_subsys_outputs( parent_path, subsys_block_path, outputs, var,node_name,  x2, y2, isBranch, branchIdx)
ID = BUtils.adapt_block_name(var{1});
SrcBlkH = get_param(subsys_block_path,'PortHandles');
for i=1:numel(outputs)
    output = outputs(i);
    output_adapted = BUtils.adapt_block_name(output,node_name);
    if exist('isBranch','var') && isBranch
        output_adapted = strcat(output_adapted, '_branch_', num2str(branchIdx));
    end
    output_path = strcat(parent_path,'/',ID,'_output_',output_adapted);
    add_block('simulink/Signal Routing/Goto',...
        output_path,...
        'GotoTag',output_adapted,...
        'Position',[(x2+300) y2 (x2+350) (y2+50)]);
    y2 = y2 + 150;
    DstBlkH = get_param(output_path, 'PortHandles');
    add_line(parent_path, SrcBlkH.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
end
end
%%
function [x2, y2] = process_branch(new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2)
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
    branch_ID = strcat(ID,'_branch_',b{1});
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
    [x4, y4] = instrs_process(new_model_name, branch_path, branch_exprs, branch_ID, x4, y4);
    
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
        branch_path = strcat(branch_block_path,'/',ID,'_branch_',b{1});
        SrcBlkH = get_param(branch_path,'PortHandles');
        add_line(branch_block_path, SrcBlkH.Outport(i), DstBlkH.Inport(j), 'autorouting', 'on');
        j = j + 1;
    end
    
    y3 = y3 + 150;
end
end
