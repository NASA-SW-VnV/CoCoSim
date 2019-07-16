classdef MATLABFunction_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % MATLABFunction_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampletime, varargin)
            
            %% add Matlab Function node
            [main_node, external_nodes ] = ...
                    nasa_toLustre.frontEnd.MF_To_LustreNode.mfunction2node(obj, parent,  blk,  xml_trace, lus_backend, coco_backend, main_sampletime);
            obj.addExtenal_node(main_node);
            obj.addExtenal_node(external_nodes);
            %% add Matlab Function call
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            codes = {};
            node_name = main_node.getName();
            if isempty(inputs)
                inputs{1} = nasa_toLustre.lustreAst.BooleanExpr(true);
            end
            codes{end+1} = nasa_toLustre.lustreAst.LustreEq(outputs, nasa_toLustre.lustreAst.NodeCallExpr(node_name, inputs));
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
        end
        %%
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

