classdef LustDTLib
    %LustDTLib This class is a set of Lustre dataType conversions.
    properties
    end
    
    methods(Static)
        
        function [node, external_nodes_i, opens] = template()
            opens = {};
            external_nodes_i = {};
            node = '';
        end
              
        
        
        %%
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
        
        %%
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
        function [node, external_nodes, opens] = getIntToIntSaturate(dt)
            opens = {};
            external_nodes = {};

            format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
            format = [format, 'y= if x > %d then %d  \n\t'];
            format = [format, 'else if x < %d then %d \n\telse x;\ntel\n\n'];
            v_max = double(intmax(dt));
            v_min = double(intmin(dt));
            node_name = strcat('int_to_', dt, '_saturate');
            node = sprintf(format, node_name, v_max, v_max, v_min, v_min);            
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
       
        %%
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
        
        % Nearest Rounds number to the nearest representable value.
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
        
        % Round Rounds number to the nearest representable value.
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
        
        % Rounds each element of the input signal to the nearest integer towards zero.
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
       
        
    end
    
end

