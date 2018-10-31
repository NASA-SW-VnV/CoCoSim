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
            try
                TOLUSTRE_SF_COMPILER = evalin('base', 'TOLUSTRE_SF_COMPILER');
            catch
                TOLUSTRE_SF_COMPILER =2;
            end
            if TOLUSTRE_SF_COMPILER == 1
                % if using old lustre compiler for Stateflow. Uncomment this
                node_name = get_full_name( blk, true );
            else
                % the new compiler
                node_name = SLX2LusUtils.node_name_format(blk);
            end
            
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
        
        function options = getUnsupportedOptions(obj,~, blk, varargin)
            % Check inputs and outputs dimenstion
            InportsWidth = blk.CompiledPortWidths.Inport;
            for i=1:numel(InportsWidth)
                if InportsWidth(i) > 1
                    obj.addUnsupported_options(...
                        sprintf(['Inport number %d in block %s is not a '...
                         'scalare. Only scalar inputs are supported in Stateflow chart.'],....
                         i, blk.Origin_path));
                end
            end
            OutportsWidth = blk.CompiledPortWidths.Outport;
            for i=1:numel(OutportsWidth)
                if OutportsWidth(i) > 1
                    obj.addUnsupported_options(...
                        sprintf(['Outport number %d in block %s is not a '...
                         'scalare. Only scalar outputs are supported in Stateflow chart.'],....
                         i, blk.Origin_path));
                end
            end
            % get all states unsupportedOptions
            
            % get all junctions unsupported Options
            
            
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end

end

