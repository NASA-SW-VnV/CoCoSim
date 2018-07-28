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
        
        function [node, external_nodes_i, opens] = template()
            opens = {};
            external_nodes_i = {};
            node = '';
        end
        
        %% sqrt
        function [node, external_nodes_i] = get_sqrt()
            opens = {};
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
        %% mod_real
        function [node, external_nodes_i, opens] = get_mod_real()
            opens = {};
            external_nodes_i = {};
            format = 'node mod_real(x, y: real;)\nreturns( z: real );\n';
            format = [format, '(*@contract\n\t'];
            format = [format, 'guarantee x=0.0 => z = 0.0;\n\t'];
            format = [format, 'guarantee y=0.0 => z = x;\n\t'];
            format = [format, '--sign(x) = sign(y) and abs(x) < abs(y)\n\t'];% because z takes the sign of y
            format = [format, 'guarantee 0.0 < x and x < y => z = x ;\n\t'];
            format = [format, 'guarantee y < x and x < 0.0 => z = x ;\n\t'];
            format = [format, '--sign(x) <> sign(y) and abs(x) < abs(y)\n\t'];% because z takes the sign of y
            format = [format, 'guarantee 0.0 < x and x < -y => z = x + y ;\n\t'];
            format = [format, 'guarantee -y < x and x < 0.0 => z = x + y;\n\t'];
            
            format = [format, '-- sign(z) = sign(y) and abs(z) < abs(y)\n\t'];
            format = [format, 'guarantee y > 0.0 => 0.0 <= z and z < y;\n\t'];
            format = [format, 'guarantee y < 0.0 => y < z and z <= 0.0;\n\t'];
            format = [format, '*)\nlet\ntel\n'];
            node = sprintf(format);
        end
        %% rem_real
        function [node, external_nodes_i, opens] = get_rem_real()
            opens = {};
            external_nodes_i = {'abs_real'};
            format = 'node rem_real(x, y: real;)\nreturns( z: real );\n';
            format = [format, '(*@contract\n\t'];
            format = [format, 'guarantee x=0.0 => z = 0.0;\n\t'];
            format = [format, 'guarantee y=0.0 => z = x;\n\t'];
            format = [format, 'guarantee abs_real(x) < abs_real(y) => z = x;\n\t'];
            format = [format, 'guarantee abs_real(z) < abs_real(y);\n\t'];
            format = [format, '-- sign(z) = sign(x) \n\t'];
            format = [format, 'guarantee x > 0.0 => z >= 0.0;\n\t'];
            format = [format, 'guarantee x < 0.0 => z <= 0.0;\n\t'];
            format = [format, '*)\nlet\ntel\n'];
            node = sprintf(format);
        end
    end
    
end

