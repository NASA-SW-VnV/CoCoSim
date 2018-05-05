classdef ExtLib
    %EXTLIB This function  is used in getExternalLibrariesNodes function.
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
        
        %%
        function [node, external_nodes_i, opens] = get__min_int()
            [node, external_nodes_i, opens] = ExtLib.getMinMax('min', 'int');
        end
        function [node, external_nodes_i, opens] = get__min_real()
            [node, external_nodes_i, opens] = ExtLib.getMinMax('min', 'real');
        end
        function [node, external_nodes_i, opens] = get__max_int()
            [node, external_nodes_i, opens] = ExtLib.getMinMax('max', 'int');
        end
        function [node, external_nodes_i, opens] = get__max_real()
            [node, external_nodes_i, opens] = ExtLib.getMinMax('max', 'real');
        end
        function [node, external_nodes_i, opens] = getMinMax(minOrMAx, dt)
            opens = {};
            external_nodes_i = {};
            format = 'node %s (x, y: %s)\nreturns(z:%s);\nlet\n\t z = if (x %s y) then x else y;\ntel\n\n';
            node_name = strcat('_', minOrMAx, '_', dt);
            if strcmp(minOrMAx, 'min')
                op = '<';
            else
                op = '>';
            end
            node = sprintf(format, node_name, dt, dt, op);
            
        end
        %%
        
        function [node, external_nodes_i, opens] = get_lustrec_math()
            opens = {'lustrec_math'};
            external_nodes_i = {};
            node = '';
        end
        
        function [node, external_nodes_i, opens] = get_simulink_math_fcn()
            opens = {'simulink_math_fcn'};
            external_nodes_i = {};
            node = '';
        end
        
        function [node, external_nodes_i, opens] = get_int_to_real()
            opens = {'conv'};
            external_nodes_i = {};
            node = '';
        end
        
        function [node, external_nodes_i, opens] = get_real_to_int()
            opens = {'conv'};
            external_nodes_i = {};
            node = '';
        end
        
        %%
        function [node, external_nodes_i, opens] = get_real_to_bool()
            [node, external_nodes_i, opens] = ExtLib.getToBool('real');
        end
        function [node, external_nodes_i, opens] = get_int_to_bool()
            [node, external_nodes_i, opens] = ExtLib.getToBool('int');
        end
        function [node, external_nodes_i, opens] = getToBool(dt)
            opens = {};
            external_nodes_i = {};
            format = 'node %s (x: %s)\nreturns(y:bool);\nlet\n\t y= (x <> %s);\ntel\n\n';
            node_name = strcat(dt, '_to_bool');
            if strcmp(dt, 'int')
                zero = '0';
            else
                zero = '0.0';
            end
            node = sprintf(format, node_name, dt, zero);
            
        end
        
        %%
        function [node, external_nodes_i, opens] = get_bool_to_int()
            [node, external_nodes_i, opens] = ExtLib.getBoolTo('int');
        end
        function [node, external_nodes_i, opens] = get_bool_to_real()
            [node, external_nodes_i, opens] = ExtLib.getBoolTo('real');
        end
        function [node, external_nodes_i, opens] = getBoolTo(dt)
            opens = {};
            external_nodes_i = {};
            format = 'node %s (x: bool)\nreturns(y:%s);\nlet\n\t y= if x then %s else %s;\ntel\n\n';
            node_name = strcat('bool_to_', dt);
            if strcmp(dt, 'int')
                zero = '0';
                one = '1';
            else
                zero = '0.0';
                one = '1.0';
            end
            node = sprintf(format, node_name, dt, one, zero);
            
        end
        
        %%
        function [node, external_nodes_i, opens] = get__AND_Bitwise_8()
            [node, external_nodes_i, opens] = ExtLib.getANDBitwise(8);
        end
        function [node, external_nodes_i, opens] = get__AND_Bitwise_16()
            [node, external_nodes_i, opens] = ExtLib.getANDBitwise(16);
        end
        function [node, external_nodes_i, opens] = get__AND_Bitwise_32()
            [node, external_nodes_i, opens] = ExtLib.getANDBitwise(32);
        end
        
        function [node, external_nodes, opens] = getANDBitwise(n)
            opens = {};
            external_nodes = {};
            
            code = {};
            for i=0:n-1
                v2_pown = 2^i;
                code{end+1} = sprintf('%d*((x / %d) mod 2)*((y / %d) mod 2)', v2_pown, v2_pown, v2_pown);
            end
            code = MatlabUtils.strjoin(code, ' \n\t+ ');
            node_name = strcat('_AND_Bitwise_', num2str(n));
            
            format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z = %s;\ntel\n\n'];
            node = sprintf(format, node_name, code);
            
            
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_8()
            [node, external_nodes_i, opens] = ExtLib.getORBitwise(8);
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_16()
            [node, external_nodes_i, opens] = ExtLib.getORBitwise(16);
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_32()
            [node, external_nodes_i, opens] = ExtLib.getORBitwise(32);
        end
        function [node, external_nodes, opens] = getORBitwise(n)
            opens = {};
            external_nodes = {};
            
            code = {};
            for i=0:n-1
                v2_pown = 2^i;
                code{end+1} = sprintf('%d*(((((x / %d) mod 2) + ((y / %d) mod 2) + ((x / %d) mod 2)*((y / %d) mod 2))) mod 2)',...
                    v2_pown, v2_pown, v2_pown, v2_pown, v2_pown);
            end
            code = MatlabUtils.strjoin(code, ' \n\t+ ');
            node_name = strcat('_OR_Bitwise_', num2str(n));
            
            format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z = %s;\ntel\n\n'];
            node = sprintf(format, node_name, code);
            
            
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_8()
            [node, external_nodes_i, opens] = ExtLib.getXORBitwise(8);
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_16()
            [node, external_nodes_i, opens] = ExtLib.getXORBitwise(16);
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_32()
            [node, external_nodes_i, opens] = ExtLib.getXORBitwise(32);
        end
        
        function [node, external_nodes, opens] = getXORBitwise(n)
            opens = {};
            external_nodes = {};
            
            code = {};
            for i=0:n-1
                v2_pown = 2^i;
                code{end+1} = sprintf('%d*(((x / %d) + (y / %d)) mod 2)', v2_pown, v2_pown, v2_pown);
            end
            code = MatlabUtils.strjoin(code, ' \n\t+ ');
            node_name = strcat('_XOR_Bitwise_', num2str(n));
            
            format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z = %s;\ntel\n\n'];
            node = sprintf(format, node_name, code);
            
            
        end
        %%
        function [node, external_nodes_i, opens] = get_int_to_int8()
            [node, external_nodes_i, opens] = ExtLib.getIntToInt('int8');
        end
        function [node, external_nodes_i, opens] = get_int_to_uint8()
            [node, external_nodes_i, opens] = ExtLib.getIntToInt('uint8');
        end
        function [node, external_nodes_i, opens] = get_int_to_int16()
            [node, external_nodes_i, opens] = ExtLib.getIntToInt('int16');
        end
        function [node, external_nodes_i, opens] = get_int_to_uint16()
            [node, external_nodes_i, opens] = ExtLib.getIntToInt('uint16');
        end
        function [node, external_nodes_i, opens] = get_int_to_int32()
            [node, external_nodes_i, opens] = ExtLib.getIntToInt('int32');
        end
        function [node, external_nodes_i, opens] = get_int_to_uint32()
            [node, external_nodes_i, opens] = ExtLib.getIntToInt('uint32');
        end
        function [node, external_nodes, opens] = getIntToInt(dt)
            opens = {};
            
            v_max = double(intmax(dt));
            v_min = double(intmin(dt));
            nb_int = (v_max - v_min + 1);
            node_name = strcat('int_to_', dt);
            
            format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
            format = [format, 'y= if x > %d then %d + rem_int_int((x - %d - 1),%d) \n\t'];
            format = [format, 'else if x < %d then %d + rem_int_int((x - (%d) + 1),%d) \n\telse x;\ntel\n\n'];
            node = sprintf(format, node_name, v_max, v_min, v_max, nb_int,...
                v_min, v_max, v_min, nb_int);
            
            external_nodes = {'rem_int_int'};
            
        end
        
        %%
        function [node, external_nodes_i, opens] = get__Floor()
            opens = {'conv'};
            external_nodes_i = {};
            % Round towards minus infinity.
            format = '--Round towards minus infinity..\n ';
            format = [format,  'node _Floor (x: real)\nreturns(y:int);\nlet\n\t'];
            format = [format, 'y= if x < 0.0 then real_to_int(x) - 1 \n\t'];
            format = [format, 'else real_to_int(x);\ntel\n\n'];
            node = sprintf(format);
        end
        % this one for "Rounding" Simulink block, it is different from Floor by
        % returning a real instead of int.
        function [node, external_nodes_i, opens] = get__floor()
            opens = {'conv'};
            external_nodes_i = {'_Floor'};
            % Round towards minus infinity.
            format = '--Rounds each element of the input signal to the nearest integer value towards minus infinity.\n ';
            format = [format,  'node _floor (x: real)\nreturns(y:real);\nlet\n\t'];
            format = [format, 'y= int_to_real(_Floor(x));\ntel\n\n'];
            node = sprintf(format);
        end
        
        
        
        %%
        function [node, external_nodes_i, opens] = get__Ceiling()
            opens = {'conv'};
            external_nodes_i = {};
            % Round towards plus infinity.
            format = '--Round towards plus infinity.\n ';
            format = [ format ,'node _Ceiling (x: real)\nreturns(y:int);\nlet\n\t'];
            format = [format, 'y= if x < 0.0 then real_to_int(x) \n\t'];
            format = [format, 'else real_to_int(x) + 1;\ntel\n\n'];
            node = sprintf(format);
        end
        % this one for "Rounding" block, it is different from Ceiling by
        % returning a real instead of int.
        function [node, external_nodes_i, opens] = get__ceil()
            opens = {'conv'};
            external_nodes_i = {'_Ceiling'};
            % Round towards minus infinity.
            format = '--Rounds each element of the input signal to the nearest integer towards positive infinity.\n ';
            format = [format,  'node _ceil (x: real)\nreturns(y:real);\nlet\n\t'];
            format = [format, 'y= int_to_real(_Ceiling(x));\ntel\n\n'];
            node = sprintf(format);
        end
        
        %%
        function [node, external_nodes, opens] = get__Convergent()
            %Rounds number to the nearest representable value.
            %If a tie occurs, rounds to the nearest even integer.
            %Equivalent to the Fixed-Point Designer? convergent function.
            opens = {};
            format = '--Rounds number to the nearest representable value.\n ';
            format = [ format ,'node _Convergent (x: real)\nreturns(y:int);\nlet\n\t'];
            format = [ format , 'y = if (x > 0.5) then\n\t\t\t'];
            format = [ format , 'if (fmod(x, 2.0) = 0.5) '];
            format = [ format , ' then _Floor(x)\n\t\t\t'];
            format = [ format , ' else _Floor(x + 0.5)\n\t\t'];
            format = [ format , ' else\n\t\t'];
            format = [ format , ' if (x >= -0.5) then 0 \n\t\t'];
            format = [ format , ' else \n\t\t\t'];
            format = [ format , ' if (fmod(x, 2.0) = -0.5) then _Ceiling(x)\n\t\t\t'];
            format = [ format , ' else _Ceiling(x - 0.5);'];
            format = [ format , '\ntel\n\n'];
            
            
            node = sprintf(format);
            external_nodes = {'fmod', '_Floor', '_Ceiling'};
            
        end
        
        %% Nearest Rounds number to the nearest representable value.
        %If a tie occurs, rounds toward positive infinity. Equivalent to the Fixed-Point Designer nearest function.
        function [node, external_nodes, opens] = get__Nearest()
            opens = {};
            format = '--Rounds number to the nearest representable value.\n--If a tie occurs, rounds toward positive infinity\n ';
            format = [ format ,'node _Nearest (x: real)\nreturns(y:int);\nlet\n\t'];
            format = [ format , 'y = if (_fabs(x) >= 0.5) then _Floor(x + 0.5)\n\t'];
            format = [ format , ' else 0;'];
            format = [ format , '\ntel\n\n'];
            
            
            node = sprintf(format);
            external_nodes = { '_Floor', '_Ceiling', '_fabs'};
        end
        
        %% Round Rounds number to the nearest representable value.
        %If a tie occurs, rounds positive numbers toward positive infinity and rounds negative numbers toward negative infinity. Equivalent to the Fixed-Point Designer round function.
        function [node, external_nodes, opens] = get__Round()
            opens = {};
            format = '--Rounds number to the nearest representable value.\n';
            format = [format , '--If a tie occurs,rounds positive numbers toward positive infinity and rounds negative numbers toward negative infinity\n '];
            format = [ format ,'node _Round (x: real)\nreturns(y:int);\nlet\n\t'];
            format = [ format , 'y = if (x >= 0.5) then _Floor(x + 0.5)\n\t\t'];
            format = [ format , ' else if (x > -0.5) then 0 \n\t\t'];
            format = [ format , ' else _Ceiling(x - 0.5);'];
            format = [ format , '\ntel\n\n'];
            
            
            node = sprintf(format);
            external_nodes = {'_Floor', '_Ceiling'};
        end
        % this one for "Rounding" block, it is different from Ceiling by
        % returning a real instead of int.
        function [node, external_nodes_i, opens] = get__round()
            opens = {'conv'};
            external_nodes_i = {'_Round'};
            % Round towards minus infinity.
            format = '--Rounds each element of the input signal to the nearest integer.\n ';
            format = [format,  'node _round (x: real)\nreturns(y:real);\nlet\n\t'];
            format = [format, 'y= int_to_real(_Round(x));\ntel\n\n'];
            node = sprintf(format);
        end
        
        %% Rounds each element of the input signal to the nearest integer towards zero.
        function [node, external_nodes, opens] = get__Fix()
            opens = {};
            format = '--Rounds number to the nearest integer towards zero.\n';
            format = [ format ,'node _Fix (x: real)\nreturns(y:int);\nlet\n\t'];
            format = [ format , 'y = if (x >= 0.5) then _Floor(x)\n\t\t'];
            format = [ format , ' else if (x > -0.5) then 0 \n\t\t'];
            format = [ format , ' else _Ceiling(x);'];
            format = [ format , '\ntel\n\n'];
            
            
            node = sprintf(format);
            external_nodes = {'_Floor', '_Ceiling'};
        end
        % this one for "Rounding" block, it is different from Fix by
        % returning a real instead of int.
        function [node, external_nodes_i, opens] = get__fix()
            opens = {'conv'};
            external_nodes_i = {'_Fix'};
            % Round towards minus infinity.
            format = '--Round towards minus infinity..\n ';
            format = [format,  'node _fix (x: real)\nreturns(y:real);\nlet\n\t'];
            format = [format, 'y= int_to_real(_Fix(x));\ntel\n\n'];
            node = sprintf(format);
        end
        %%
        function [node, external_nodes_i, opens] = get_fmod()
            opens = {'lustrec_math'};
            external_nodes_i = {};
            node = '';
        end
        
        function [node, external_nodes_i, opens] = get_rem_int_int()
            opens = {};
            external_nodes_i = {};
            format = 'node rem_int_int (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z= if (x < 0) and (y > 0) then (x mod -y) \n\t'];
            format = [format, 'else (x mod y);\ntel\n\n'];
            
            node = sprintf(format);
        end
        
        %%
        function [node, external_nodes_i, opens] = get__fabs()
            opens = {};
            external_nodes_i = {};
            format = 'node _fabs (x:real)\nreturns(z:real);\nlet\n\t';
            format = [format, 'z= if (x >= 0.0)  then x \n\t'];
            format = [format, 'else -x;\ntel\n\n'];
            
            node = sprintf(format);
        end
        
        %% Digital clock
        
        function [node, external_nodes_i, opens] = get__DigitalClock()
            opens = {};
            external_nodes_i = {'_round', '_fabs'};
            format = 'node _DigitalClock (simulationTime, SampleTime:real)\nreturns(q:real);\n';
            format = [format, 'var b:bool;\n'];
            format = [format, 'let\n\t'];
            format = [format, 'b = _fabs(simulationTime - _round(simulationTime/SampleTime) * SampleTime) <= 0.000000001; \n\t'];
            format = [format, 'q = if b then simulationTime else pre q; \n'];
            format = [format, 'tel\n\n'];
            node = sprintf(format);
        end
    end
    
end

