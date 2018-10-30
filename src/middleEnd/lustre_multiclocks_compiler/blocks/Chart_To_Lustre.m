classdef Chart_To_Lustre < Block_To_Lustre
    % Chart_To_Lustre translates Stateflow chart to Lustre.
    % This version is temporal using the old compiler. New version using
    % lustref compiler is comming soon.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            % if using old lustre compiler for Stateflow. Uncomment this
            %node_name = get_full_name( blk, true );
            % the new compiler
            node_name = SLX2LusUtils.node_name_format(blk);
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            [triggerInputs] = SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
            codes = {};
            if ~isempty(triggerInputs)
                cond = cell(1, blk.CompiledPortWidths.Trigger);
                for i=1:blk.CompiledPortWidths.Trigger
                    TriggerType = blk.StateflowContent.Events{i}.Trigger;
                    [lusTriggerportDataType, zero] = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Trigger{1});
                    [triggerCode, status] = SLX2LusUtils.getResetCode(...
                        TriggerType, lusTriggerportDataType, triggerInputs{i} , zero);
                    if status
                        display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                            TriggerType, blk.Origin_path), ...
                            MsgType.ERROR, 'Constant_To_Lustre', '');
                        return;
                    end
                    v_name = sprintf('%s_Event%d', node_name, i);
                    obj.addVariable(LustreVar(v_name, 'bool'));
                    codes{end+1} = LustreEq(VarIdExpr(v_name), triggerCode);
                    cond{i} = VarIdExpr(v_name);
                end
                inputs = [cond, inputs];
            end
            if isempty(inputs)
                inputs{1} = BooleanExpr(true);
            end
            
           
            codes{end+1} = LustreEq(outputs, NodeCallExpr(node_name, inputs));

            obj.setCode( codes );
            obj.addVariable(outputs_dt); 
        end
        
        function options = getUnsupportedOptions(obj,~, ~, varargin)
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end

end

