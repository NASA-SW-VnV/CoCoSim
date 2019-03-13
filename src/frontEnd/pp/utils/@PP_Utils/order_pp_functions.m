
function [ordered_functions, fcts_map]  = ...
    order_pp_functions(pp_order_map, pp_handled_blocks, pp_unhandled_blocks)


    if isempty(pp_order_map)
        warning('Order map ''pp_order_map'' has not been defined. Please check pp_order.m');
        pp_order_map = containers.Map();
    end
    if isempty(pp_handled_blocks)
        errordlg('Order map ''pp_handled_blocks'' has not been defined. Please check pp_order.m');
    end
    if isempty(pp_unhandled_blocks)
        pp_unhandled_blocks = {};
    end

    priorities = sort(cell2mat(pp_order_map.keys));
    if ~isempty(priorities)
        lowest_priority = priorities(end);
    else
        lowest_priority = 0;
    end

    % fct -> priority
    fcts_map = containers.Map('KeyType', 'char', 'ValueType', 'int32');

    fcts_map = PP_Utils.update_priority(fcts_map, pp_order_map);
    fcts_map = PP_Utils.extract_fcts(fcts_map, pp_handled_blocks, lowest_priority);
    fcts_map = PP_Utils.extract_fcts(fcts_map, pp_unhandled_blocks, -1);
    ordered_functions = PP_Utils.get_ordered_functions(fcts_map);

end
        
 