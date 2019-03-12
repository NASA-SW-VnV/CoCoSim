classdef Delay_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Delay_To_Lustre
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
            
            [DelayLength, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.DelayLength);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.DelayLength, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            [DelayLengthUpperLimit, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.DelayLengthUpperLimit);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.DelayLengthUpperLimit, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            [lustre_code, delay_node_code, variables, external_libraries] = ...
                nasa_toLustre.blocks.Delay_To_Lustre.get_code( parent, blk, ...
                blk.InitialConditionSource, blk.DelayLengthSource,...
                DelayLength, DelayLengthUpperLimit, blk.ExternalReset, blk.ShowEnablePort, xml_trace );
            obj.addVariable(variables);
            obj.addExternal_libraries(external_libraries);
            obj.addExtenal_node(delay_node_code);
            obj.setCode(lustre_code);
            
            
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            [DelayLength, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.DelayLength);
            if status
                obj.addUnsupported_options(...
                    sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.DelayLength, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            [~, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.DelayLengthUpperLimit);
            if status
                obj.addUnsupported_options(...
                    sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.DelayLengthUpperLimit, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            [InitialCondition, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.InitialCondition);
            if status
                obj.addUnsupported_options(...
                    sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.InitialCondition, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            if numel(InitialCondition) > 1 ...
                    && ~( ...
                    strcmp(blk.DelayLengthSource, 'Dialog') && DelayLength == 1 )
                obj.addUnsupported_options(...
                    sprintf('InitialCondition %s in block %s is not supported for delay > 1',...
                    blk.InitialCondition, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            ExternalReset = blk.ExternalReset;
            isReset = ~strcmp(ExternalReset, 'None');
            if isReset
                if ~nasa_toLustre.utils.SLX2LusUtils.resetTypeIsSupported(ExternalReset)
                    obj.addUnsupported_options(sprintf('This External reset type [%s] is not supported in block %s.', ...
                    ExternalReset, HtmlItem.addOpenCmd(blk.Origin_path)));
                end
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    methods(Static = true)
        [lustre_code, delay_node_code, variables, external_libraries] = ...
                get_code( parent, blk, InitialConditionSource, DelayLengthSource,...
                DelayLength, DelayLengthUpperLimit, ExternalReset, ShowEnablePort, xml_trace )
        
        [delay_node] = getDelayNode(node_name, ...
                u_DT, delayLength, isDelayVariable, isReset, isEnabel)
   
        code = getExpofNDelays(x0, u, d)

    end
    
end

