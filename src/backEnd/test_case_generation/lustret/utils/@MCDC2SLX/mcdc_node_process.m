%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mcdc_node_process(new_model_name, nodes, node, ...
        node_block_path, mdlTraceRoot, block_pos, xml_trace)
    mcdc_variables_names = mcdcVariables(nodes.(node));
    display_msg([num2str(numel(mcdc_variables_names)) ' mc-dc conditions has been generated'...
        ' for node ' nodes.(node).original_name], MsgType.INFO, 'mcdc2slx', '');
    if ~isempty(mcdc_variables_names)
        % extract "lhs" names from instructions
        blk_exprs = nodes.(node).instrs;
        lhs_instrID_map = containers.Map();
        lhs_rhs_map = containers.Map();
        for var = fieldnames(blk_exprs)'
            switch blk_exprs.(var{1}).kind
                case 'branch'
                    lhs_list = blk_exprs.(var{1}).outputs;
                otherwise
                    lhs_list = blk_exprs.(var{1}).lhs;
            end
            
            % extract "rhs" names from instructions
            rhs_list = {};
            switch blk_exprs.(var{1}).kind
                case {'pre', 'local_assign'}
                    rhs_type = blk_exprs.(var{1}).rhs.type;
                    if strcmp(rhs_type, 'variable')
                        rhs_list = blk_exprs.(var{1}).rhs.value;
                    end
                    
                case 'reset' % lhs = rhs;
                    rhs_list = blk_exprs.(var{1}).rhs;
                    
                case {'operator', 'functioncall', 'statelesscall', 'statefulcall'}
                    for i=1:numel(blk_exprs.(var{1}).args)
                        rhs_list{i} = blk_exprs.(var{1}).args(i).value;
                    end
                case 'branch'
                    blk_inputs = blk_exprs.(var{1}).inputs;
                    for i=1:numel(blk_inputs)
                        rhs_list{i} = blk_inputs(i).name;
                    end
            end
            if iscell(lhs_list)
                for i=1:numel(lhs_list)
                    lhs_instrID_map(lhs_list{i}) = var{1};
                    lhs_rhs_map(lhs_list{i}) = rhs_list;
                end
            else
                lhs_instrID_map(lhs_list) = var{1};
                lhs_rhs_map(lhs_list) = rhs_list;
            end
        end
        
        % get variables original names
        originalNamesMap = containers.Map();
        for input=nodes.(node).inputs
            originalNamesMap(input.name) = input.original_name;
        end
        for output=nodes.(node).outputs
            originalNamesMap(output.name) = output.original_name;
        end
        for local=nodes.(node).locals
            originalNamesMap(local.name) = local.original_name;
        end
        % get tracable variables names
        traceable_variables = SLX2Lus_Trace.get_tracable_variables(mdlTraceRoot,...
            nodes.(node).original_name);
        
        [instructionsIDs, inputList]= get_mcdc_instructions(mcdc_variables_names, ...
            lhs_instrID_map, lhs_rhs_map, originalNamesMap, traceable_variables);
        
        % creat mcdc block
        x2 = 200;
        y2= -50;
        
        if ~isempty(xml_trace)
            xml_trace.create_Node_Element(node_block_path,  nodes.(node).original_name);
            xml_trace.create_Inputs_Element();
        end
        add_block('built-in/Subsystem', node_block_path);%,...
        %             'TreatAsAtomicUnit', 'on');
        set_param(node_block_path, 'Position', block_pos);
        
        % Outputs
        
        [x2, y2] = process_mcdc_outputs(node_block_path, mcdc_variables_names, '', x2, y2);
        
        
        % Inputs
        blk_inputs(1) =struct('name', '', 'datatype', '', 'original_name', '');
        for i=1:numel(inputList)
            found = true;
            
            if ismember(inputList{i}, {nodes.(node).inputs.name})
                blk_inputs(i) = nodes.(node).inputs(...
                    ismember( {nodes.(node).inputs.name}, inputList{i}));
            elseif ismember(inputList{i}, {nodes.(node).outputs.name})
                blk_inputs(i) = nodes.(node).outputs(...
                    ismember( {nodes.(node).outputs.name}, inputList{i}));
                
            elseif ismember(inputList{i}, {nodes.(node).locals.name})
                blk_inputs(i) = nodes.(node).locals(...
                    ismember( {nodes.(node).locals.name}, inputList{i}));
            else
                display_msg(['couldn''t find variable ' inputList{i} ' in EMF'],...
                    MsgType.ERROR, 'MCDC2SLX', '');
                found = false;
                blk_inputs(i) = [];
            end
            if found
                var_orig_name = originalNamesMap(inputList{i});
                [block_name, out_port_nb, dimension] = ...
                    SLX2Lus_Trace.get_SlxBlockName_from_LusVar_UsingXML(...
                    mdlTraceRoot, nodes.(node).original_name, var_orig_name);
                
                xml_trace.add_Input(var_orig_name, block_name, ...
                    str2num(out_port_nb), str2num(dimension));
            end
        end
        [x2, y2] = Lus2SLXUtils.process_inputs(node_block_path, blk_inputs, '', x2, y2);
        
        
        
        % Instructions
        %deal with the invariant expressions for the cocospec Subsys,
        blk_exprs = {};
        for i=1:numel(instructionsIDs)
            blk_exprs.(instructionsIDs{i}) = nodes.(node).instrs.(instructionsIDs{i});
        end
        Lus2SLXUtils.instrs_process(nodes, new_model_name, node_block_path, blk_exprs, '', x2, y2, []);
        
    end
end

