classdef MF_To_LustreNode
    %MF_To_LustreNode translates a MATLAB Function to Lustre node
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods(Static)
        [main_node, external_nodes ] = ...
            mfunction2node(blkObj, parent,  blk,  xml_trace, lus_backend, coco_backend, main_sampleTime, varargin);
        [blk , Inputs, Outputs] = creatInportsOutports(blk);
        [external_nodes, failed] = getMFunctionCode(blkObj, parent,  blk, Inputs)
        [script, failed] = getAllRequiredFunctionsInOneScript(blk)
        [functions, failed] = getFunctionList(blk, script)
        [data_map, failed] = getFuncsDataMap(blk, script, functions, Inputs)
        [fun_node,failed ]  = getFuncCode(func, data_map, blkObj, parent, blk)
        [fun_node] = getFunHeader(func, blk, data_map)
    end
    
    
    
end

