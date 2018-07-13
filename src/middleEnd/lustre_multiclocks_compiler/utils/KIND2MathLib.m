classdef KIND2MathLib
    %KIND2MathLib This class  is used in getExternalLibrariesNodes function.
    %To abstract some mathematical functions with Kind2 contracts.
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
        
        function [node, external_nodes_i] = template()
            external_nodes_i = {};
            node = '';
        end
        
        %% sqrt
        function [node, external_nodes_i] = get_sqrt()
            external_nodes_i = {};
            format = 'node sqrt(x: real;)\nreturns( y: real );\n';
            format = [format, '(*@contract\n\t'];
            format = [format, 'assume x >= 0.0;\n\t'];
            format = [format, 'guarantee  y >= 0.0;\n\t'];
            format = [format, 'guarantee y <= x;\n'];
            format = [format, 'guarantee y*y = x;\n'];
            format = [format, '*)\nlet\ntel\n'];
            node = sprintf(format);
        end
       
    end
    
end

