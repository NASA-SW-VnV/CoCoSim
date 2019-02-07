
function [x2, y2] = instrs_process(nodes, new_model_name, node_block_path, blk_exprs, node_name,  x2, y2, xml_trace)
    for var = fieldnames(blk_exprs)'
        try
            switch blk_exprs.(var{1}).kind
                case 'arrow' % lhs = True -> False;
                    [x2, y2] = Lus2SLXUtils.process_arrow(node_block_path, blk_exprs, var, node_name,  x2, y2);

                case 'pre' % lhs = pre rhs;
                    [x2, y2] = Lus2SLXUtils.process_pre(node_block_path, blk_exprs, var, node_name, x2, y2);

                case 'local_assign' % lhs = rhs;
                    [x2, y2] = Lus2SLXUtils.process_local_assign(node_block_path, blk_exprs, var, node_name,  x2, y2);

                case 'reset' % lhs = rhs;
                    [x2, y2] = Lus2SLXUtils.process_reset(node_block_path, blk_exprs, var, node_name,  x2, y2);

                case 'operator'
                    [x2, y2] = Lus2SLXUtils.process_operator(node_block_path, blk_exprs, var, node_name, x2, y2);

                case {'statelesscall', 'statefulcall'}
                    [x2, y2] = Lus2SLXUtils.process_node_call(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace);

                case 'functioncall'
                    [x2, y2] = Lus2SLXUtils.process_functioncall( node_block_path, blk_exprs, var, node_name, x2, y2);
                case 'branch'
                    [x2, y2] = Lus2SLXUtils.process_branch(nodes, new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace);
            end
        catch ME
            display_msg(['couldn''t translate expression ' var{1} ' to Simulink'], MsgType.ERROR, 'LUS2SLX', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'LUS2SLX', '');
            %         continue;
            rethrow(ME)
        end
    end
end
