function code = ifElseCode(obj, parent, blk, outputs, inputs, inports_dt, IfExp)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    
    % Go over outputs
    nbOutputs=numel(outputs);
    if isempty(IfExp{nbOutputs})
        n_conds = nbOutputs - 1;
    else
        n_conds = nbOutputs;
    end
    thens = cell(1, n_conds + 1);
    conds = cell(1, n_conds);
    data_map = nasa_toLustre.blocks.Fcn_To_Lustre.createDataMap(inputs, inports_dt);
    for j=1:nbOutputs
        lusCond = nasa_toLustre.blocks.If_To_Lustre.formatConditionToLustre(obj, ...
            IfExp{j}, inputs, data_map, parent, blk);
        if j==nbOutputs && isempty(IfExp{j})
            %default condition
            thens{j} = nasa_toLustre.blocks.If_To_Lustre.outputsValues(nbOutputs, j);
        elseif j==nbOutputs
            %last condition
            conds{j} = lusCond;
            thens{j} = nasa_toLustre.blocks.If_To_Lustre.outputsValues(nbOutputs, j);
            thens{j + 1} = nasa_toLustre.blocks.If_To_Lustre.outputsValues(nbOutputs, 0);
        else
            conds{j} = lusCond;
            thens{j} = nasa_toLustre.blocks.If_To_Lustre.outputsValues(nbOutputs, j);
        end

    end
    code = nasa_toLustre.lustreAst.LustreEq(outputs, ...
        nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
end

