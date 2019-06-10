function extNode = get_read_table_node(blk_name, U_inputs, U_LusDt)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This function generate Lustre external node that will return T[i] for a
    % given table T and index i.
    
    % header for external node
    NodeName = sprintf('%s_getTableElement', blk_name);
    
    % get outputs
    output_name = nasa_toLustre.lustreAst.VarIdExpr('y');
    outputs{1} = nasa_toLustre.lustreAst.LustreVar(output_name, U_LusDt);
    
    % get inputs
    nbU = length(U_inputs);
    inputs_name = cell(1, nbU+1);
    inputs = cell(1, nbU+1);
    % add index
    inputs_name{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr('x');
    inputs{1} = ...
        nasa_toLustre.lustreAst.LustreVar(...
        inputs_name{1},'int');
    % add table elements
    inputs_name(2:end) = U_inputs;
    inputs(2:end) = cellfun(@(x) ...
        nasa_toLustre.lustreAst.LustreVar(x.getId(), U_LusDt), U_inputs, 'UniformOutput', 0);
    
    
    [body, vars] = nasa_toLustre.blocks.Lookup_nD_To_Lustre.addInlineIndexFromArrayIndicesCode(...
        U_inputs, output_name,  inputs_name{1});
    vars = nasa_toLustre.lustreAst.LustreVar.removeVar(vars, output_name);

    
    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(NodeName)
    extNode.setInputs(inputs);
    extNode.setOutputs(outputs);
    extNode.setLocalVars(vars);
    extNode.setBodyEqs(body);
    extNode.setMetaInfo('get a table element');
    
end

