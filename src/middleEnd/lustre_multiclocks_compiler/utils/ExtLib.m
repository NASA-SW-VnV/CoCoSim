classdef ExtLib
    %EXTLIB This class  is used in getExternalLibrariesNodes function.
    %To support an external library you need to follow the template.
    % Function name should be : get_LibraryName. For example a library
    % called int_to_int8 will be handled in get_int_to_int8,
    % the Matlab function should return :
    %   - node: The equivalent lustre node if exists.
    %   - external_nodes: returns external libraries that depends on,
    %       for example _Convergent library depends on _Floor library.
    %   - opens: the open libraries that will be needed, such as conv,
    %       lustrect_math or simulink_math_fcn.
    
    properties
    end
    
    methods(Static)
        
        function [node, external_nodes_i, opens] = template()
            opens = {};
            external_nodes_i = {};
            node = '';
        end
        
        %% Clocks
        function [node, external_nodes_i, opens] = get__make_clock()
            opens = {};
            external_nodes_i = {};
            format = 'node _make_clock(per: int; ph: int)\nreturns( clk: bool );\nvar cnt: int;\n';
            format = [format, 'let\n\t'];
            format = [format, 'cnt   = ((per - ph) -> (pre(cnt) + 1)) mod per ;\n\t'];
            format = [format, 'clk = if (cnt = 0) then true else false ;\n'];
            format = [format, 'tel\n'];
            node = sprintf(format);
        end
        
    end
    
end

