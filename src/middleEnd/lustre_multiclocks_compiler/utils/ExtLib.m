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
        
        %% LustMathLib
        function [node, external_nodes_i, opens] = get__min_int()
            [node, external_nodes_i, opens] = LustMathLib.getMinMax('min', 'int');
        end
        
        function [node, external_nodes_i, opens] = get__min_real()
            [node, external_nodes_i, opens] = LustMathLib.getMinMax('min', 'real');
        end
        
        function [node, external_nodes_i, opens] = get__max_int()
            [node, external_nodes_i, opens] = LustMathLib.getMinMax('max', 'int');
        end
        
        function [node, external_nodes_i, opens] = get__max_real()
            [node, external_nodes_i, opens] = LustMathLib.getMinMax('max', 'real');
        end

        function [node, external_nodes_i, opens] = get_lustrec_math()
            [node, external_nodes_i, opens] = LustMathLib.get_lustrec_math();
        end
        
        function [node, external_nodes_i, opens] = get_simulink_math_fcn()
            [node, external_nodes_i, opens] = LustMathLib.get_simulink_math_fcn();
        end
        
        %Bitwise operations
        function [node, external_nodes_i, opens] = get__AND_Bitwise_8()
            [node, external_nodes_i, opens] = LustMathLib.getANDBitwise(8);
        end
        function [node, external_nodes_i, opens] = get__AND_Bitwise_16()
            [node, external_nodes_i, opens] = LustMathLib.getANDBitwise(16);
        end
        function [node, external_nodes_i, opens] = get__AND_Bitwise_32()
            [node, external_nodes_i, opens] = LustMathLib.getANDBitwise(32);
        end
       
        function [node, external_nodes_i, opens] = get__OR_Bitwise_8()
            [node, external_nodes_i, opens] = LustMathLib.getORBitwise(8);
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_16()
            [node, external_nodes_i, opens] = LustMathLib.getORBitwise(16);
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_32()
            [node, external_nodes_i, opens] = LustMathLib.getORBitwise(32);
        end
       
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_8()
            [node, external_nodes_i, opens] = LustMathLib.getXORBitwise(8);
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_16()
            [node, external_nodes_i, opens] = LustMathLib.getXORBitwise(16);
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_32()
            [node, external_nodes_i, opens] = LustMathLib.getXORBitwise(32);
        end
       
        function [node, external_nodes_i, opens] = get__NOT_Bitwise_Signed()
            [node, external_nodes_i, opens] = LustMathLib.getNOTBitwiseSigned();
        end
        function [node, external_nodes_i, opens] = get__NOT_Bitwise_Unsigned_8()
            [node, external_nodes_i, opens] = LustMathLib.getNOTBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens] = get__NOT_Bitwise_Unsigned_16()
            [node, external_nodes_i, opens] = LustMathLib.getNOTBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens] = get__NOT_Bitwise_Unsigned_32()
            [node, external_nodes_i, opens] = LustMathLib.getNOTBitwiseUnsigned(32);
        end
        
        % The following functions assume "/" and "mod" in Lustre as in
        % euclidean division for integers.
        function [node, external_nodes_i, opens] = get_abs_int()
            [node, external_nodes_i, opens] = LustMathLib.get_abs_int();
        end
        function [node, external_nodes_i, opens] = get_int_div_Ceiling()
            [node, external_nodes_i, opens] = LustMathLib.get_int_div_Ceiling();
        end
        function [node, external_nodes_i, opens] = get_int_div_Nearest()
           [node, external_nodes_i, opens] = LustMathLib.get_int_div_Nearest();
        end
       
        function [node, external_nodes_i, opens] = get_fmod()
             [node, external_nodes_i, opens] = LustMathLib.get_fmod();
        end
        function [node, external_nodes_i, opens] = get_rem_int_int()
            [node, external_nodes_i, opens] = LustMathLib.get_rem_int_int();
        end
        function [node, external_nodes_i, opens] = get_mod_int_int()
            [node, external_nodes_i, opens] = LustMathLib.get_mod_int_int();
        end
        
        function [node, external_nodes_i, opens] = get__fabs()
            [node, external_nodes_i, opens] = LustMathLib.get__fabs();
        end
        
        %
        %% LustDTLib
        function [node, external_nodes_i, opens] = get_int_to_real()
            [node, external_nodes_i, opens] = LustDTLib.get_int_to_real();
        end
        
        function [node, external_nodes_i, opens] = get_real_to_int()
            [node, external_nodes_i, opens] = LustDTLib.get_real_to_int();
        end
        
        function [node, external_nodes_i, opens] = get_real_to_bool()
            [node, external_nodes_i, opens] = LustDTLib.getToBool('real');
        end
        
        function [node, external_nodes_i, opens] = get_int_to_bool()
            [node, external_nodes_i, opens] = LustDTLib.getToBool('int');
        end
        
        function [node, external_nodes_i, opens] = get_bool_to_int()
            [node, external_nodes_i, opens] = LustDTLib.getBoolTo('int');
        end
        
        function [node, external_nodes_i, opens] = get_bool_to_real()
            [node, external_nodes_i, opens] = LustDTLib.getBoolTo('real');
        end
        
        function [node, external_nodes_i, opens] = get_int_to_int8()
            [node, external_nodes_i, opens] = LustDTLib.getIntToInt('int8');
        end
        function [node, external_nodes_i, opens] = get_int_to_uint8()
            [node, external_nodes_i, opens] = LustDTLib.getIntToInt('uint8');
        end
        function [node, external_nodes_i, opens] = get_int_to_int16()
            [node, external_nodes_i, opens] = LustDTLib.getIntToInt('int16');
        end
        function [node, external_nodes_i, opens] = get_int_to_uint16()
            [node, external_nodes_i, opens] = LustDTLib.getIntToInt('uint16');
        end
        function [node, external_nodes_i, opens] = get_int_to_int32()
            [node, external_nodes_i, opens] = LustDTLib.getIntToInt('int32');
        end
        function [node, external_nodes_i, opens] = get_int_to_uint32()
            [node, external_nodes_i, opens] = LustDTLib.getIntToInt('uint32');
        end
        function [node, external_nodes_i, opens] = get_int_to_int8_saturate()
            [node, external_nodes_i, opens] = LustDTLib.getIntToIntSaturate('int8');
        end
        function [node, external_nodes_i, opens] = get_int_to_uint8_saturate()
            [node, external_nodes_i, opens] = LustDTLib.getIntToIntSaturate('uint8');
        end
        function [node, external_nodes_i, opens] = get_int_to_int16_saturate()
            [node, external_nodes_i, opens] = LustDTLib.getIntToIntSaturate('int16');
        end
        function [node, external_nodes_i, opens] = get_int_to_uint16_saturate()
            [node, external_nodes_i, opens] = LustDTLib.getIntToIntSaturate('uint16');
        end
        function [node, external_nodes_i, opens] = get_int_to_int32_saturate()
            [node, external_nodes_i, opens] = LustDTLib.getIntToIntSaturate('int32');
        end
        function [node, external_nodes_i, opens] = get_int_to_uint32_saturate()
            [node, external_nodes_i, opens] = LustDTLib.getIntToIntSaturate('uint32');
        end
       
        
        function [node, external_nodes_i, opens] = get__Floor()
            [node, external_nodes_i, opens] = LustDTLib.get__Floor();
        end
        % this one for "Rounding" Simulink block, it is different from Floor by
        % returning a real instead of int.
        function [node, external_nodes_i, opens] = get__floor()
            [node, external_nodes_i, opens] = LustDTLib.get__floor();
        end

        function [node, external_nodes_i, opens] = get__Ceiling()
            [node, external_nodes_i, opens] = LustDTLib.get__Ceiling();
        end
        % this one for "Rounding" block, it is different from Ceiling by
        % returning a real instead of int.
        function [node, external_nodes, opens] = get__ceil()
            [node, external_nodes, opens] = LustDTLib.get__ceil();
        end
        
        function [node, external_nodes, opens] = get__Convergent()
            [node, external_nodes, opens] = LustDTLib.get__Convergent();
        end
        
        % Nearest Rounds number to the nearest representable value.
        %If a tie occurs, rounds toward positive infinity. Equivalent to the Fixed-Point Designer nearest function.
        function [node, external_nodes, opens] = get__Nearest()
            [node, external_nodes, opens] = LustDTLib.get__Nearest();
        end
        
        % Round Rounds number to the nearest representable value.
        %If a tie occurs, rounds positive numbers toward positive infinity and rounds negative numbers toward negative infinity. Equivalent to the Fixed-Point Designer round function.
        function [node, external_nodes, opens] = get__Round()
            [node, external_nodes, opens] = LustDTLib.get__Round();
        end
        % this one for "Rounding" block, it is different from Ceiling by
        % returning a real instead of int.
        function [node, external_nodes, opens] = get__round()
            [node, external_nodes, opens] = LustDTLib.get__round();
        end
        
        % Rounds each element of the input signal to the nearest integer towards zero.
        function [node, external_nodes, opens] = get__Fix()
            [node, external_nodes, opens] = LustDTLib.get__Fix();
        end
        % this one for "Rounding" block, it is different from Fix by
        % returning a real instead of int.
        function [node, external_nodes, opens] = get__fix()
            [node, external_nodes, opens] = LustDTLib.get__fix();
        end
        
        %% BlocksLib.m
        function [node, external_nodes, opens] = get__DigitalClock()
            [node, external_nodes, opens] = BlocksLib.get__DigitalClock();
        end
    end
    
end

