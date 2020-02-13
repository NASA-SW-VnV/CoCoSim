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

function [x2, y2] = process_branch(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;

    ID = coco_nasa_utils.SLXUtils.adapt_block_name(var{1});
    branch_block_path = fullfile(node_block_path, ID);
    add_block('built-in/Subsystem', branch_block_path,...
        'Position',[(x2+200) y2 (x2+250) (y2+50)]);
    %    'TreatAsAtomicUnit', 'on', ...


    x3 = 50;
    y3 = 50;

    branch_struct = blk_exprs.(var{1});
    %% Outputs
    blk_outputs = branch_struct.outputs;
    [x3, y3] = Lus2SLXUtils.process_outputs(branch_block_path, blk_outputs, ID, x3, y3);

    %% Inputs
    blk_inputs = branch_struct.inputs;
    [x3, y3] = Lus2SLXUtils.process_inputs(branch_block_path, blk_inputs, ID, x3, y3);

    %% link outputs from outside
    outputs = branch_struct.outputs;
    [x2, y4] =Lus2SLXUtils.link_subsys_outputs( node_block_path, branch_block_path, outputs, var, node_name, x2, y2);


    %% link inputs from outside
    inputs = branch_struct.inputs;
    [x2, y5] = Lus2SLXUtils.link_subsys_inputs( node_block_path, branch_block_path, inputs, var, node_name, x2, y2);

    y2 = max(y4, y5);

    %% check if it's a stateless if/else
    useSwitch = useSwitchInsteadOfIF(branch_struct);
    
    %% add IF block with IF expressions
    IF_path = strcat(branch_block_path,'/',ID,'_IF');
    branches = branch_struct.branches;
    y3 = y3 + 150;
    if useSwitch
        add_block('simulink/Signal Routing/Switch',...
            IF_path,...
            'Criteria', 'u2 ~= 0', ...
            'Position',[(x3+100) y3 (x3+150) (y3+50)]);
    else
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
        add_block('simulink/Ports & Subsystems/If',...
            IF_path,...
            'IfExpression', IfExpression, ...
            'ElseIfExpressions', ElseIfExpressions, ...
            'ShowElse', 'off', ...
            'Position',[(x3+100) y3 (x3+150) (y3+50)]);
    end
    %% add Guard input
    guard_path = strcat(branch_block_path,'/',ID,'_guard');
    guard = branch_struct.guard.value;
    guard_type = branch_struct.guard.type;
    guard_adapted = coco_nasa_utils.SLXUtils.adapt_block_name(guard, ID);
    if strcmp(guard_type, 'constant')
        add_block('simulink/Commonly Used Blocks/Constant',...
            guard_path,...
            'Value', guard,...
            'Position',[x3 y3 (x3+50) (y3+50)]);
        %     set_param(guard_path, 'OutDataTypeStr','Inherit: Inherit via back propagation');
        dt = Lus2SLXUtils.getArgDataType(branch_struct.guard);
        
        if strcmp(dt, 'bool')
            set_param(guard_path, 'OutDataTypeStr', 'boolean');
        elseif strcmp(dt, 'int')
            set_param(guard_path, 'OutDataTypeStr', 'int32');
        elseif strcmp(dt, 'real')
            set_param(guard_path, 'OutDataTypeStr', 'double');
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
    if useSwitch
        add_line(branch_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(2), 'autorouting', 'on');
    else
        add_line(branch_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
    end
    y3 = y3 + 150;
    x3 = x3 + 300;
    %% branches
    idx = 1;
    for b=fieldnames(branches)'
        branch_ID = strcat(ID,'_branch_',branches.(b{1}).guard_value);
        branch_path = strcat(branch_block_path,'/',branch_ID);
        if useSwitch
            add_block('simulink/Ports & Subsystems/Subsystem',...
                branch_path,...
                'Position',[(x3+100) y3 (x3+150) (y3+50)]);
        else
            add_block('simulink/Ports & Subsystems/If Action Subsystem',...
                branch_path,...
                'Position',[(x3+100) y3 (x3+150) (y3+50)]);
        end
        try
            delete_line(branch_path, 'In1/1', 'Out1/1');
            delete_block(strcat(branch_path,'/In1'));
            delete_block(strcat(branch_path,'/Out1'));
        catch
        end
        

        % link Sction subsys inputs
        % Outputs
        x4 = 50;
        y4 = 50;
        blk_outputs = branch_struct.outputs;
        addSignalConversion = ~useSwitch;
        [x4, y4] = Lus2SLXUtils.process_outputs(branch_path, blk_outputs, branch_ID, x4, y4, addSignalConversion);

        % Inputs
        blk_inputs = branches.(b{1}).inputs;
        [x4, y4] = Lus2SLXUtils.process_inputs(branch_path, blk_inputs, branch_ID, x4, y4);
        [x3, y3] = Lus2SLXUtils.link_subsys_inputs( branch_block_path, branch_path, blk_inputs, b, ID, x3, y3);


        % instructions
        branch_exprs = branches.(b{1}).instrs;
        [x4, y4] = Lus2SLXUtils.instrs_process(nodes, new_model_name, branch_path, branch_exprs, branch_ID, x4, y4, xml_trace);

        % link IF/Switch with Action subsystem
        if useSwitch
            DstBlkH = get_param(IF_path,'PortHandles');
            SrcBlkH = get_param(branch_path,'PortHandles');
            if strcmp(branches.(b{1}).guard_value, 'true')
                add_line(branch_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
            else
                add_line(branch_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(3), 'autorouting', 'on');
            end
        else
            DstBlkH = get_param(branch_path,'PortHandles');
            SrcBlkH = get_param(IF_path,'PortHandles');
            add_line(branch_block_path, SrcBlkH.Outport(idx), DstBlkH.Ifaction(1), 'autorouting', 'on');
        end
        
        %
        idx = idx + 1;
        y3 = y3 + 150;
    end

    %% Merge outputs
    outputs = branch_struct.outputs;
    for i=1:numel(outputs)
        output = outputs(i);
        output_adapted = coco_nasa_utils.SLXUtils.adapt_block_name(output, ID);
        merge_path = strcat(branch_block_path,'/',output_adapted,'_merge');
        output_path = strcat(branch_block_path,'/',output_adapted,'_merged');
        nb_merge = numel(fieldnames(branches));
        add_block('simulink/Signal Routing/Goto',...
            output_path,...
            'GotoTag',output_adapted,...
            'TagVisibility', 'local', ...
            'Position',[(x3+300) y3 (x3+350) (y3+50)]);
        if useSwitch
            DstBlkH = get_param(output_path, 'PortHandles');
            SrcBlkH = get_param(IF_path,'PortHandles');
            add_line(branch_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
            
        else
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
        end

        y3 = y3 + 150;
    end
    %% expand branch subsystem
    try
        ExpandNonAtomicSubsystems_pp(branch_block_path);
        delete(find_system(node_block_path,'FindAll','on','type','annotation' , 'AnnotationType', 'area_annotation'));
    catch
    end
end

%%
function b = useSwitchInsteadOfIF(branch_struct)
    b = false;
    %TODO: support more than one output
    if length(branch_struct.outputs) == 1 ...
            && length(fieldnames(branch_struct.branches)) == 2
        branches = branch_struct.branches;
        branch_names = fieldnames(branches);
        if ismember('true', branch_names) && ismember('false', branch_names)
            % New
            b = ~Lus2SLXUtils.instr_mayHaveMemory(branch_struct);
            % OLD
%             if length(branches.true.inputs) == 1 ...
%                     && length(branches.true.instrs) == 1 ...
%                     && length(branches.false.inputs) == 1 ...
%                     && length(branches.false.instrs) == 1
%                 true_instr = branches.true.instrs;
%                 true_instr_names = fieldnames(true_instr);
%                 false_instr = branches.false.instrs;
%                 false_instr_names = fieldnames(false_instr);
%                 b = strcmp(true_instr.(true_instr_names{1}).kind, 'local_assign') ...
%                     && strcmp(true_instr.(true_instr_names{1}).rhs.type, 'variable') ... 
%                     && strcmp(false_instr.(false_instr_names{1}).kind, 'local_assign') ...
%                     && strcmp(false_instr.(false_instr_names{1}).rhs.type, 'variable');
%                 
%             end
        end
    end
end

