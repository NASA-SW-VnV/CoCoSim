function [node, external_nodes_i, opens, abstractedNodes] = get_inverse_code(lus_backend,n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Khanh Tringh <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % support 2x2 matrix inversion
    % support 3x3 matrix inversion
    % support 4x4 matrix inversion
    % contract for 2x2 to 7x7 matrix inversion
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i ={};
    node_name = sprintf('_inv_M_%dx%d',n,n);
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setIsMain(false);
    vars = {};
    body = {};
    
    % inputs & outputs
    % a: inputs, ai: outputs
    a = cell(n,n);
    ai = cell(n,n);
    for i=1:n
        for j=1:n
            a{i,j} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('a%d%d',i,j));
            ai{i,j} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('ai%d%d',i,j));
        end
    end
    inputs = cell(1,n*n);
    outputs = cell(1,n*n);
    inline_a = cell(1,n*n);
    inline_ai = cell(1,n*n);
    counter = 0;
    for j=1:n
        for i=1:n
            counter = counter + 1;
            inline_a{counter} = a{i,j};
            inline_ai{counter} = ai{i,j};
            inputs{counter} = nasa_toLustre.lustreAst.LustreVar(a{i,j},'real');
            outputs{counter} = nasa_toLustre.lustreAst.LustreVar(ai{i,j},'real');
        end
    end
    if LusBackendType.isKIND2(lus_backend)
        contractBody = getContractBody_nxn_inverstion(n,inline_a,inline_ai);
        contract = nasa_toLustre.lustreAst.LustreContract();
        contract.setBodyEqs(contractBody);
        node.setLocalContract(contract);
    end
    % inversion and contract
    if  n > 4
        node.setIsImported(true);
        abstractedNodes = {sprintf('Inverse Matrix of dimension %d', n)};
    elseif n==4 && LusBackendType.isKIND2(lus_backend)
        node.setIsImported(true);
    else
        Lustre_inversion = 0;
        if n == 2 || n == 3 || n ==4
            Lustre_inversion = 1;
        end
        if Lustre_inversion == 1
            vars = cell(1,n*n+1);
            det = nasa_toLustre.lustreAst.VarIdExpr('det');
            vars{1} = nasa_toLustre.lustreAst.LustreVar(det,'real');
            % adj: adjugate
            adj = cell(n,n);
            for i=1:n
                for j=1:n
                    adj{i,j} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('adj%d%d',i,j));
                    vars{(i-1)*n+j+1} = nasa_toLustre.lustreAst.LustreVar(adj{i,j},'real');
                end
            end
            
            body = get_Det_Adjugate_Code(n,det,a,adj);
            
            % define inverse
            for i=1:n
                for j=1:n
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(ai{i,j},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.DIVIDE,adj{i,j},det));
                end
            end
        else
            display_msg(...
                sprintf('Matrix inversion for higher than 4x4 matrix is not supported in LustMathLib'), ...
                MsgType.ERROR, 'LustMathLib', '');
        end
    end
    
    % set node
    node.setInputs(inputs);
    node.setOutputs(outputs);
    node.setBodyEqs(body);
    node.setLocalVars(vars);
    
end
