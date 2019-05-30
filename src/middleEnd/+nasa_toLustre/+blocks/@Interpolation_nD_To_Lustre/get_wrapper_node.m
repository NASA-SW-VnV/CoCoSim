function extNode =  get_wrapper_node(~,interpolationExtNode,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interpolation_using_PreLookup
    
    % node header
    wrapper_header.NodeName = ...
        sprintf('%s_Interp_nD_wrapper_node',blkParams.blk_name);
    
    % node outputs, only y_out
    wrapper_header.output = interpolationExtNode.outputs;
    wrapper_header.output_name{1} = nasa_toLustre.lustreAst.VarIdExpr(...
        wrapper_header.output{1}.id);
    
    body_all = {};
    vars_all = {};
    numDims = blkParams.NumberOfTableDimensions;
    
    if blkParams.tableIsInputPort
        numTableInput = length(blkParams.Table);
    else
        numTableInput = 0;
    end
    
    wrapper_header.inputs = cell(1,2*numDims +  numTableInput);
    wrapper_header.inputs_name = ...
        cell(1,2*numDims+numTableInput);
    new_fraction_name = cell(1,numDims);
    fraction_in_name = cell(1,numDims);
    k_name = cell(1,numDims);
    vars = cell(1,numDims);
    body = cell(1,2*numDims);
    for i=1:numDims
        % wrapper header
        wrapper_header.inputs_name{(i-1)*2+1} = ...
            nasa_toLustre.lustreAst.VarIdExpr(sprintf('k_in_dim_%d',i));
        wrapper_header.inputs{(i-1)*2+1} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            wrapper_header.inputs_name{(i-1)*2+1},'int');
        wrapper_header.inputs_name{(i-1)*2+2} = ...
            nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('f_in_dim_%d',i));
        fraction_in_name{i} = wrapper_header.inputs_name{(i-1)*2+2};
        
        new_fraction_name{i} = ...
            nasa_toLustre.lustreAst.VarIdExpr(sprintf(...
            'fraction_dim_%d',i));
        k_name{i} = wrapper_header.inputs_name{(i-1)*2+1};
        wrapper_header.inputs{(i-1)*2+2} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            wrapper_header.inputs_name{(i-1)*2+2},'real');
        
        vars{i} = nasa_toLustre.lustreAst.LustreVar(...
            new_fraction_name{i},'real');
        % clipped higher than 1 fraction at 1
        fraction_conds = {};
        fraction_thens = {};
        fraction_conds{1} = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.GT, ...
            fraction_in_name{i},...
            nasa_toLustre.lustreAst.RealExpr(1.0));
        fraction_thens{1} = nasa_toLustre.lustreAst.RealExpr(1.0);
        fraction_conds{2} = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.LT, ...
            fraction_in_name{i},...
            nasa_toLustre.lustreAst.RealExpr(0.0));
        fraction_thens{2} = nasa_toLustre.lustreAst.RealExpr(0.0);
        fraction_thens{3} = fraction_in_name{i};
        rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(fraction_conds, fraction_thens);
        body{(i-1)*2+2} = nasa_toLustre.lustreAst.LustreEq(...
            new_fraction_name{i},rhs);
    end
    tableInputsNames = [];
    if blkParams.tableIsInputPort
        % add table
        tableInputsNames = cell(1, length(blkParams.Table));
        for i=1:length(blkParams.Table)
            t = blkParams.Table{end - i + 1};
            tableInputsNames{end - i +1} = t;
            wrapper_header.inputs_name{end - i + 1} = t;
            wrapper_header.inputs{end - i + 1} = ...
                nasa_toLustre.lustreAst.LustreVar(t, 'real');
        end
    end
    body_all = [body_all  body];
    vars_all = [vars_all  vars];
    
    
    
    % doing subscripts to index in Lustre.  Need subscripts, and
    % dimension jump.
    [body, vars,Ast_dimJump] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addDimJumpCode(...
        blkParams);
    body_all = [body_all  body];
    vars_all = [vars_all  vars];
    
    % preparing inputs for Interp_Using_Pre_ext_node.
    % ki in Simulink is 0 based, indices in
    % Lustre _Interp_Using_Pre_ext_node are 1 based.  Correction
    % to ki(s) are made here.  In addition correction to ki(s)
    % to handle Simulink convention for the setting of
    % "use last breakpoint for input at or above upper limit".
    % note that Simulink will allow for ki input to be larger than number
    % of breakpoints, in this case, Simulink just use the highest
    % breakpoint
    bound_nodes_expression = cell(numDims,2);
    oneBased_bound_nodes_name = cell(numDims,1);
    bound_nodes_name = cell(numDims,2);
    vars = {};
    body = {};
    tableSize = blkParams.TableDim;
    for i=1:numDims
        curDimNumBreakpoints = tableSize(i);
        % correction for zero based (simulink inputs) to one based
        % (_Interp_Using_Pre_ext_node)
        oneBased_bound_nodes_name{i} = ...
            nasa_toLustre.lustreAst.VarIdExpr(sprintf(...
            'oneBased_bound_node_low_dim_%d',i));
        
        
        bound_nodes_name{i,1} = ...
            nasa_toLustre.lustreAst.VarIdExpr(sprintf(...
            'bound_node_low_dim_%d',i));
        bound_nodes_name{i,2} = ...
            nasa_toLustre.lustreAst.VarIdExpr(sprintf(...
            'bound_node_high_dim_%d',i));
        vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            oneBased_bound_nodes_name{i},'int');
        vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            bound_nodes_name{i,1},'int');
        vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            bound_nodes_name{i,2},'int');
        
        bound_nodes_expression{i,1} = ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
            wrapper_header.inputs_name{(i-1)*2+1},...
            nasa_toLustre.lustreAst.IntExpr(1));
        bound_nodes_expression{i,2} = ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
            wrapper_header.inputs_name{(i-1)*2+1},...
            nasa_toLustre.lustreAst.IntExpr(2));
        
        
        % defining bound nodes from k_in accounting for zero based and
        % ?valid index input may reach last index?  setting
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
            oneBased_bound_nodes_name{i},...
            bound_nodes_expression{i,1});
        
        % calculate lower bound node
        low_conds = cell(1,2);
        low_thens = cell(1,3);
        low_conds{1} = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.GT, ...
            oneBased_bound_nodes_name{i},...
            nasa_toLustre.lustreAst.IntExpr(curDimNumBreakpoints-1));
        low_thens{1} = nasa_toLustre.lustreAst.IntExpr(curDimNumBreakpoints-1);
        
        low_conds{2} = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.LT, ...
            oneBased_bound_nodes_name{i},...
            nasa_toLustre.lustreAst.IntExpr(1));
        low_thens{2} = nasa_toLustre.lustreAst.IntExpr(1);
        
        low_thens{3} = oneBased_bound_nodes_name{i};
        
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
            bound_nodes_name{i,1}, ...
            nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(low_conds, low_thens));
        
        rhs = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
            bound_nodes_name{i,1},...
            nasa_toLustre.lustreAst.IntExpr(1));
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
            bound_nodes_name{i,2},rhs);
    end
    body_all = [body_all  body];
    vars_all = [vars_all  vars];
    
    if  blkParams.directLookup
        [body, vars] = ...
            nasa_toLustre.blocks.Interpolation_nD_To_Lustre.addDirectLookupNodeCode_Interpolation_nD(...
            blkParams,bound_nodes_name,...
            Ast_dimJump,fraction_in_name,k_name);
        body_all = [body_all  body];
        vars_all = [vars_all  vars];
        
        nodeCallInputs{1} = blkParams.direct_sol_inline_index_VarIdExpr;
        nodeCallInputs = [nodeCallInputs, ....
            tableInputsNames];
        bodyf{1} = nasa_toLustre.lustreAst.LustreEq(...
            wrapper_header.output_name{1}, ...
            nasa_toLustre.lustreAst.NodeCallExpr(...
            interpolationExtNode.name, ...
            nodeCallInputs));
        body_all = [body_all  bodyf];
    else
        % for interpolation/extrapolation method, inputs are index and
        % weight of each bounding node
        numDims = blkParams.NumberOfTableDimensions;
        numBoundNodes = 2^blkParams.NumberOfTableDimensions;
        
        % calculating linear shape function value for multidimensional
        % interpolation from fi of each dimension
        N_shape_node = cell(1,numBoundNodes);
        body = cell(1,numBoundNodes);
        vars = cell(1,numBoundNodes);
            
        for i=1:numBoundNodes
            N_shape_node{i} = nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('N_shape_%d',i));
            vars{i} = nasa_toLustre.lustreAst.LustreVar(...
                N_shape_node{i},'real');
            numerator_terms = cell(1,numDims);
            for j=1:numDims
                node2bin = strcat('000000', dec2bin(i-1));
                ExtrapCond = [];
                if  strcmp(blkParams.InterpMethod,'Linear') && strcmp(blkParams.ExtrapMethod,'Clip')
                    fracName = new_fraction_name{j};
                    if strcmp(blkParams.ValidIndexMayReachLast, 'on')
                        ExtrapCond = nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.GTE, ...
                            oneBased_bound_nodes_name{j},...
                            nasa_toLustre.lustreAst.IntExpr(tableSize(j)));
                    end
                else
                    fracName = fraction_in_name{j};
                end
                    
                if strcmp(node2bin(end-j+1), '0') %shapeNodeSign(i,j)==-1
                    term = nasa_toLustre.lustreAst.BinaryExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                        nasa_toLustre.lustreAst.RealExpr(1.),...
                        fracName);
                    if isempty(ExtrapCond)
                        numerator_terms{j} = term; % 1-fraction
                    else
                        numerator_terms{j} = ...
                            nasa_toLustre.lustreAst.IteExpr(ExtrapCond, ...
                            nasa_toLustre.lustreAst.RealExpr('0.0'), term, true);
                    end
                else
                    if isempty(ExtrapCond)
                        numerator_terms{j} = fracName; % 1-fraction
                    else
                        numerator_terms{j} = ...
                            nasa_toLustre.lustreAst.IteExpr(ExtrapCond, ...
                            nasa_toLustre.lustreAst.RealExpr('1.0'), fracName, true);
                    end
                end
            end
            numerator = ...
                nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                numerator_terms);
            body{i} = nasa_toLustre.lustreAst.LustreEq(...
                N_shape_node{i},numerator);
        end
        body_all = [body_all  body];
        vars_all = [vars_all  vars];
        
        [body, vars, bounding_nodes] = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.addBoundNodeInlineIndexCode(...
            bound_nodes_name,Ast_dimJump,blkParams);
        body_all = [body_all  body];
        vars_all = [vars_all  vars];
        
        % define args for interpolation call
        interpolation_call_inputs_args = cell(1,2*numBoundNodes);
        for i=1:numBoundNodes
            interpolation_call_inputs_args{(i-1)*2+1} = bounding_nodes{i};
            interpolation_call_inputs_args{(i-1)*2+2} = N_shape_node{i};
        end
        interpolation_call_inputs_args = [interpolation_call_inputs_args, ....
            tableInputsNames];
        % call interpolation
        bodyf{1} = nasa_toLustre.lustreAst.LustreEq(...
            wrapper_header.output_name{1}, ...
            nasa_toLustre.lustreAst.NodeCallExpr(...
            interpolationExtNode.name, ...
            interpolation_call_inputs_args));
        
        body_all = [body_all  bodyf];
    end
    
    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(wrapper_header.NodeName)
    extNode.setInputs(wrapper_header.inputs);
    extNode.setOutputs( wrapper_header.output);
    extNode.setLocalVars(vars_all);
    extNode.setBodyEqs(body_all);
    extNode.setMetaInfo('external node code wrapper for doing Interpolation using PreLookup');
    
end

