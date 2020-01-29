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

function  [x2, y2] = process_node_call(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace)
    persistent calls_map;
    if isempty(calls_map)
        calls_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end
    
    
    
    if MatlabUtils.startsWith(blk_exprs.(var{1}).name, '_')
        % Simulink read json : _max_real is read as x_max_real
        node_fieldname = strcat('x', blk_exprs.(var{1}).name);
    else
        node_fieldname = blk_exprs.(var{1}).name;
    end
    
    ID = BUtils.adapt_block_name(node_fieldname);
    fcn_path = BUtils.get_unique_block_name(...
        strcat(node_block_path,'/',ID,'_call'));
    if ~isempty(xml_trace)

        block_pos = [(x2+100) y2 (x2+250) (y2+50)];
        if isKey(calls_map, ID) && (getSimulinkBlockHandle(calls_map(ID)) ~= -1)
            display_msg(sprintf('Using cash for subsystem %s', ID), ...
                MsgType.DEBUG, 'process_node_call', '');
            fcn_subsys = calls_map(ID);
            add_block(fcn_subsys,...
                fcn_path,...
                'Position',block_pos);
            xml_trace.create_Node_Element(fcn_path,  nodes.(node_fieldname).original_name);
        else
            Lus2SLXUtils.node_process(new_model_name, nodes, blk_exprs.(var{1}).name, fcn_path, block_pos, xml_trace);
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
            fullfile(fcn_path, 'Reset'));
        try
            % in 2017 version of Simulink there is level hold
            % option, but not on the other Simulink versions
            set_param(fullfile(fcn_path, 'Reset'), 'ResetTriggerType', 'level hold');
            isEither = false;
        catch
            set_param(fullfile(fcn_path, 'Reset'), 'ResetTriggerType', 'either');
            isEither = true;
        end
        reset_name = blk_exprs.(var{1}).reset.name;
        reset_adapted = BUtils.adapt_block_name(reset_name, node_name);
        reset_path =  BUtils.get_unique_block_name(...
            strcat(node_block_path,'/',ID,'_reset'));
        add_block('simulink/Signal Routing/From',...
            reset_path,...
            'GotoTag',reset_adapted,...
            'TagVisibility', 'local', ...
            'Position',[(x2+150) (y2-50) (x2+200) (y2-30)]);
        if isEither
            if ~bdIsLoaded('pp_lib'); load_system('pp_lib.slx'); end
            eitherTrigger_path =  BUtils.get_unique_block_name(...
                strcat(node_block_path,'/',ID,'_reset_Either'));
            add_block('pp_lib/bool_To_eitherTrigger',...
                eitherTrigger_path);
            SrcBlkH = get_param(reset_path, 'PortHandles');
            DstBlkH = get_param(eitherTrigger_path,'PortHandles');
            add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
            SrcBlkH = get_param(eitherTrigger_path, 'PortHandles');
            DstBlkH = get_param(fcn_path,'PortHandles');
            add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Reset(1), 'autorouting', 'on');
        else
            SrcBlkH = get_param(reset_path, 'PortHandles');
            DstBlkH = get_param(fcn_path,'PortHandles');
            add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Reset(1), 'autorouting', 'on');
        end
    end
    SrcBlkH = get_param(fcn_path,'PortHandles');
    y3=y2;
    for i=1:numel(blk_exprs.(var{1}).lhs)
        if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end
        output = blk_exprs.(var{1}).lhs(i);
        output_adapted = BUtils.adapt_block_name(output, node_name);
        output_path = BUtils.get_unique_block_name(...
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
        input_path = BUtils.get_unique_block_name(...
            strcat(node_block_path,'/',ID,'_In',num2str(i)));
        if strcmp(input_type, 'constant')
            add_block('simulink/Commonly Used Blocks/Constant',...
                input_path,...
                'Value', input,...
                'Position',[x2 y2 (x2+50) (y2+50)]);
            %         set_param(input_path, 'OutDataTypeStr','Inherit: Inherit via back propagation');
            dt = Lus2SLXUtils.getArgDataType(blk_exprs.(var{1}).args(i));
            
            if strcmp(dt, 'bool')
                set_param(input_path, 'OutDataTypeStr', 'boolean');
            elseif strcmp(dt, 'int')
                set_param(input_path, 'OutDataTypeStr', 'int32');
            elseif strcmp(dt, 'real')
                set_param(input_path, 'OutDataTypeStr', 'double');
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

