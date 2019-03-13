classdef PP_Utils
    
    methods (Static = true)
        [ordered_functions, fcts_map]  = ...
                order_pp_functions(pp_order_map, pp_handled_blocks, pp_unhandled_blocks)
        
        ordered_functions = get_ordered_functions(fcts_map)

        ordered_fcts_map = extract_fcts(ordered_fcts_map, map, lowest_priority)

        ordered_fcts_map = update_priority(ordered_fcts_map, pp_order_map)

    end
end