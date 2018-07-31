classdef LustMathLib
    %LustMathLib This class  is a set of Lustre math libraries.
    
    properties
    end
    
    methods(Static)
        
        function [node, external_nodes_i, opens] = template()
            opens = {};
            external_nodes_i = {};
            node = '';
        end
        
        %% Min Max
        function [node, external_nodes_i, opens] = getMinMax(minOrMAx, dt)
            opens = {};
            external_nodes_i = {};
            node_name = strcat('_', minOrMAx, '_', dt);
            if strcmp(minOrMAx, 'min')
                op = BinaryExpr.LT;
            else
                op = BinaryExpr.GT;
            end
            %format = 'node %s (x, y: %s)\nreturns(z:%s);\nlet\n\t z = if (x %s y) then x else y;\ntel\n\n';
            bodyElts = LustreEq(...
                VarIdExpr('z'), ...
                IteExpr(...
                    BinaryExpr(op, VarIdExpr('x'), VarIdExpr('y')), ...
                    VarIdExpr('x'), ...
                    VarIdExpr('y'))...
                );
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', dt), LustreVar('y', dt)});
            node.setOutputs(LustreVar('z', dt));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
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
        
        %% fabs, abs
        function [node, external_nodes_i, opens] = get__fabs()
            opens = {};
            external_nodes_i = {};
            %             format = 'node _fabs (x:real)\nreturns(z:real);\nlet\n\t';
            %             format = [format, 'z= if (x >= 0.0)  then x \n\t'];
            %             format = [format, 'else -x;\ntel\n\n'];
            
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), VarIdExpr('0.0')), ...
                    VarIdExpr('x'), ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')))...
                );
            node = LustreNode();
            node.setName('_fabs');
            node.setInputs(LustreVar('x', 'real'));
            node.setOutputs(LustreVar('z', 'real'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        function [node, external_nodes_i, opens] = get_abs_int()
            opens = {};
            external_nodes_i = {};
            %             format = 'node abs_int (x: int)\nreturns(y:int);\nlet\n\t';
            %             format = [format, 'y= if x >= 0 then x \n\t'];
            %             format = [format, 'else -x;\ntel\n\n'];
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), VarIdExpr('0')), ...
                    VarIdExpr('x'), ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')))...
                );
            node = LustreNode();
            node.setName('abs_int');
            node.setInputs(LustreVar('x', 'int'));
            node.setOutputs(LustreVar('y', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        function [node, external_nodes_i, opens] = get_abs_real()
            opens = {};
            external_nodes_i = {};
%             format = 'node abs_real (x: real)\nreturns(y:real);\nlet\n\t';
%             format = [format, 'y= if x >= 0.0 then x \n\t'];
%             format = [format, 'else -x;\ntel\n\n'];
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), VarIdExpr('0.0')), ...
                    VarIdExpr('x'), ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')))...
                );
            node = LustreNode();
            node.setName('abs_real');
            node.setInputs(LustreVar('x', 'real'));
            node.setOutputs(LustreVar('y', 'real'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        %% Bitwise operators
        function [node, external_nodes, opens] = getBitwiseSigned(op, n)
            opens = {};
            extNode = sprintf('int_to_int%d',n);
            UnsignedNode =  sprintf('_%s_Bitwise_Unsigned_%d',op, n);
            external_nodes = {strcat('LustDTLib_', extNode),...
                strcat('LustMathLib_', UnsignedNode)};
            
            node_name = sprintf('_%s_Bitwise_Signed_%d', op, n);
            v2_pown = 2^(n);
%             format = 'node %s (x, y: int)\nreturns(z:int);\nvar x2, y2:int;\nlet\n\t';
%             format = [format, 'x2 = if x < 0 then %d + x else x;\n\t'];
%             format = [format, 'y2 = if y < 0 then %d + y else y;\n\t'];
%             format = [format, 'z = %s(%s(x2, y2));\ntel\n\n'];
%             node = sprintf(format, node_name, v2_pown, v2_pown, extNode, UnsignedNode);
            bodyElts{1} = LustreEq(...
                VarIdExpr('x2'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.LT, VarIdExpr('x'), VarIdExpr('0')), ...
                    BinaryExpr(BinaryExpr.PLUS, IntExpr(v2_pown),VarIdExpr('x')), ...
                    VarIdExpr('x'))...
                );
            bodyElts{end + 1} = LustreEq(...
                VarIdExpr('y2'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.LT, VarIdExpr('y'), VarIdExpr('0')), ...
                    BinaryExpr(BinaryExpr.PLUS, IntExpr(v2_pown),VarIdExpr('y')), ...
                    VarIdExpr('y'))...
                );
            bodyElts{end + 1} = LustreEq(...
                VarIdExpr('z'), ...
                NodeCallExpr(extNode, ...
                            NodeCallExpr(UnsignedNode, ...
                                   {VarIdExpr('x2'), VarIdExpr('y2')}))...
                );
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setLocalVars({LustreVar('x2', 'int'), LustreVar('y2', 'int')})
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        %AND
        function [node, external_nodes, opens] = getANDBitwiseUnsigned(n)
            opens = {};
            external_nodes = {};
            
            args = {};
            %code{1} = sprintf('(x mod 2)*(y mod 2)');
            args{1} = BinaryExpr(...
                BinaryExpr.MULTIPLY, ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), IntExpr(2)), ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('y'), IntExpr(2)));
            for i=1:n-1
                v2_pown = 2^i;
                %code{end+1} = sprintf('%d*((x / %d) mod 2)*((y / %d) mod 2)', v2_pown, v2_pown, v2_pown);
                x_term = BinaryExpr(...
                    BinaryExpr.MOD, ...
                    BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), IntExpr(v2_pown)),...
                    IntExpr(2));
                y_term = BinaryExpr(...
                    BinaryExpr.MOD, ...
                    BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('y'), IntExpr(v2_pown)),...
                    IntExpr(2));
                args{end + 1} = BinaryExpr(...
                    BinaryExpr.MULTIPLY, ...
                    IntExpr(v2_pown),...
                    BinaryExpr(...
                        BinaryExpr.MULTIPLY, ...
                    	x_term, ...
                    	y_term));
            end
            %code = MatlabUtils.strjoin(code, ' \n\t+ ');
            rhs = LustreAst.BinaryMultiArgs(BinaryExpr.PLUS, args);
            node_name = strcat('_AND_Bitwise_Unsigned_', num2str(n));
            
            %             format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            %             format = [format, 'z = %s;\ntel\n\n'];
            %             node = sprintf(format, node_name, code);
            bodyElts = LustreEq(...
                VarIdExpr('z'), ...
                rhs);
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end 
        %NAND
        function [node, external_nodes, opens] = getNANDBitwiseUnsigned(n)
            opens = {};
            notNode = sprintf('_NOT_Bitwise_Unsigned_%d', n);
            UnsignedNode =  sprintf('_AND_Bitwise_Unsigned_%d', n);
            external_nodes = {strcat('LustMathLib_', notNode),...
                strcat('LustMathLib_', UnsignedNode)};
            
            node_name = sprintf('_NAND_Bitwise_Unsigned_%d', n);
            format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z = %s(%s(x, y));\ntel\n\n'];
            node = sprintf(format, node_name, notNode, UnsignedNode);
        end
        %NOR
        function [node, external_nodes, opens] = getNORBitwiseUnsigned(n)
            opens = {};
            notNode = sprintf('_NOT_Bitwise_Unsigned_%d', n);
            UnsignedNode =  sprintf('_OR_Bitwise_Unsigned_%d', n);
            external_nodes = {strcat('LustMathLib_', notNode),...
                strcat('LustMathLib_', UnsignedNode)};
            
            node_name = sprintf('_NOR_Bitwise_Unsigned_%d', n);
            format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z = %s(%s(x, y));\ntel\n\n'];
            node = sprintf(format, node_name, notNode, UnsignedNode);
        end
        %OR
        function [node, external_nodes, opens] = getORBitwiseUnsigned(n)
            opens = {};
            external_nodes = {};
            
            code = {};
            code{1} = sprintf('((((x mod 2) + (y mod 2) + (x mod 2)*(y mod 2))) mod 2)');
            for i=1:n-1
                v2_pown = 2^i;
                code{end+1} = sprintf('%d*(((((x / %d) mod 2) + ((y / %d) mod 2) + ((x / %d) mod 2)*((y / %d) mod 2))) mod 2)',...
                    v2_pown, v2_pown, v2_pown, v2_pown, v2_pown);
            end
            code = MatlabUtils.strjoin(code, ' \n\t+ ');
            node_name = strcat('_OR_Bitwise_Unsigned_', num2str(n));
            
            format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z = %s;\ntel\n\n'];
            node = sprintf(format, node_name, code);            
        end
        %XOR
        function [node, external_nodes, opens] = getXORBitwiseUnsigned(n)
            opens = {};
            external_nodes = {};
            
            code = {};
            code{1} = sprintf('((x + y) mod 2)');
            for i=1:n-1
                v2_pown = 2^i;
                code{end+1} = sprintf('%d*(((x / %d) + (y / %d)) mod 2)', v2_pown, v2_pown, v2_pown);
            end
            code = MatlabUtils.strjoin(code, ' \n\t+ ');
            node_name = strcat('_XOR_Bitwise_Unsigned_', num2str(n));
            
            format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z = %s;\ntel\n\n'];
            node = sprintf(format, node_name, code);
        end
        
        
        function [node, external_nodes, opens] = getNOTBitwiseUnsigned(n)
            opens = {};
            external_nodes = {};
            v2_pown = 2^n - 1;
            format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
            format = [format, 'y=  %d - x ;\ntel\n\n'];
            node_name = strcat('_NOT_Bitwise_Unsigned_', num2str(n));
            node = sprintf(format, node_name,v2_pown);
        end
        function [node, external_nodes, opens] = getNOTBitwiseSigned()
            opens = {};
            external_nodes = {};
            format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
            format = [format, 'y=   - x - 1;\ntel\n\n'];
            node_name = strcat('_NOT_Bitwise_Signed');
            node = sprintf(format, node_name);
        end
        
        %AND
        function [node, external_nodes_i, opens] = get__AND_Bitwise_Unsigned_8()
            [node, external_nodes_i, opens] = LustMathLib.getANDBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens] = get__AND_Bitwise_Unsigned_16()
            [node, external_nodes_i, opens] = LustMathLib.getANDBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens] = get__AND_Bitwise_Unsigned_32()
            [node, external_nodes_i, opens] = LustMathLib.getANDBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens] = get__AND_Bitwise_Signed_8()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('AND', 8);
        end
        function [node, external_nodes_i, opens] = get__AND_Bitwise_Signed_16()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('AND', 16);
        end
        function [node, external_nodes_i, opens] = get__AND_Bitwise_Signed_32()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('AND', 32);
        end
        %NAND
        function [node, external_nodes_i, opens] = get__NAND_Bitwise_Unsigned_8()
            [node, external_nodes_i, opens] = LustMathLib.getNANDBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens] = get__NAND_Bitwise_Unsigned_16()
            [node, external_nodes_i, opens] = LustMathLib.getNANDBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens] = get__NAND_Bitwise_Unsigned_32()
            [node, external_nodes_i, opens] = LustMathLib.getNANDBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens] = get__NAND_Bitwise_Signed_8()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('NAND', 8);
        end
        function [node, external_nodes_i, opens] = get__NAND_Bitwise_Signed_16()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('NAND', 16);
        end
        function [node, external_nodes_i, opens] = get__NAND_Bitwise_Signed_32()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('NAND', 32);
        end
       
        %OR
        function [node, external_nodes_i, opens] = get__OR_Bitwise_Unsigned_8()
            [node, external_nodes_i, opens] = LustMathLib.getORBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_Unsigned_16()
            [node, external_nodes_i, opens] = LustMathLib.getORBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_Unsigned_32()
            [node, external_nodes_i, opens] = LustMathLib.getORBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_Signed_8()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('OR', 8);
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_Signed_16()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('OR', 16);
        end
        function [node, external_nodes_i, opens] = get__OR_Bitwise_Signed_32()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('OR', 32);
        end
        %NOR
        function [node, external_nodes_i, opens] = get__NOR_Bitwise_Unsigned_8()
            [node, external_nodes_i, opens] = LustMathLib.getNORBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens] = get__NOR_Bitwise_Unsigned_16()
            [node, external_nodes_i, opens] = LustMathLib.getNORBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens] = get__NOR_Bitwise_Unsigned_32()
            [node, external_nodes_i, opens] = LustMathLib.getNORBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens] = get__NOR_Bitwise_Signed_8()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('NOR', 8);
        end
        function [node, external_nodes_i, opens] = get__NOR_Bitwise_Signed_16()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('NOR', 16);
        end
        function [node, external_nodes_i, opens] = get__NOR_Bitwise_Signed_32()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('NOR', 32);
        end
       
        %XOR
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_Unsigned_8()
            [node, external_nodes_i, opens] = LustMathLib.getXORBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_Unsigned_16()
            [node, external_nodes_i, opens] = LustMathLib.getXORBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_Unsigned_32()
            [node, external_nodes_i, opens] = LustMathLib.getXORBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_Signed_8()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('XOR', 8);
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_Signed_16()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('XOR', 16);
        end
        function [node, external_nodes_i, opens] = get__XOR_Bitwise_Signed_32()
            [node, external_nodes_i, opens] = LustMathLib.getBitwiseSigned('XOR', 32);
        end
        
        %NOT
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
        %% Integer division
        
        % The following functions assume "/" and "mod" in Lustre as in
        % euclidean division for integers.
        
        function [node, external_nodes_i, opens] = get_int_div_Ceiling()
            opens = {};
            external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
            format = '--Rounds positive and negative numbers toward positive infinity\n ';
            format = [format,  'node int_div_Ceiling (x, y: int)\nreturns(z:int);\nlet\n\t'];
            format = [format, 'z= if y = 0 then if x>0 then 2147483647 else -2147483648\n\t'];
            format = [format, 'else if x mod y = 0 then x/y\n\t'];
            format = [format, 'else if (abs_int(y) > abs_int(x) and x*y>0) then 1 \n\t'];
            format = [format, 'else if (abs_int(y) > abs_int(x) and x*y<0) then 0 \n\t'];
            format = [format, 'else if (x>0 and y < 0) then x/y \n\t'];
            format = [format, 'else if (x<0 and y > 0) then (-x)/(-y) \n\t'];
            format = [format, 'else if (x<0 and y < 0) then (-x)/(-y) + 1 \n\t'];
            format = [format, 'else x/y + 1;\ntel\n\n'];
            node = sprintf(format);
        end
        %Floor: Rounds positive and negative numbers toward negative infinity.
        function [node, external_nodes_i, opens] = get_int_div_Floor()
            opens = {};
            external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
            format = '--Rounds positive and negative numbers toward negative infinity\n ';
            format = [format,  'node int_div_Floor (x, y: int)\nreturns(z:int);\nlet\n\t'];
            format = [format, 'z= if y = 0 then if x>0 then 2147483647 else -2147483648\n\t'];
            format = [format, 'else if x mod y = 0 then x/y\n\t'];
            format = [format, 'else if (abs_int(y) > abs_int(x) and x*y>0) then 0 \n\t'];
            format = [format, 'else if (abs_int(y) > abs_int(x) and x*y<0) then -1 \n\t'];
            format = [format, 'else if (x>0 and y < 0) then x/y - 1\n\t'];
            format = [format, 'else if (x<0 and y > 0) then (-x)/(-y) - 1\n\t'];
            format = [format, 'else if (x<0 and y < 0) then (-x)/(-y)\n\t'];
            format = [format, 'else x/y;\ntel\n\n'];
            node = sprintf(format);
        end
        function [node, external_nodes_i, opens] = get_int_div_Nearest()
            opens = {};
            external_nodes_i = {};
            format = '--Rounds number to the nearest representable value. If a tie occurs, rounds toward positive infinity\n ';
            format = [format,  'node int_div_Nearest (x, y: int)\nreturns(z:int);\nlet\n\t'];
            format = [format, 'z= if y = 0 then if x>0 then 2147483647 else -2147483648\n\t'];
            format = [format, 'else if x mod y = 0 then x/y\n\t'];
            format = [format, 'else if (y > 0) and ((x mod y)*2 >= y ) then x/y+1 \n\t'];
            format = [format, 'else if (y < 0) and ((x mod y)*2 >= (-y))  then x/y-1 \n\t'];
            format = [format, 'else x/y;\ntel\n\n'];
            node = sprintf(format);
        end
        
        function [node, external_nodes_i, opens] = get_int_div_Zero()
            opens = {};
            external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
            format = '--Rounds positive and negative numbers toward positive infinity\n ';
            format = [format,  'node int_div_Zero (x, y: int)\nreturns(z:int);\nlet\n\t'];
            format = [format, 'z= if y = 0 then if x>0 then 2147483647 else -2147483648\n\t'];
            format = [format, 'else if x mod y = 0 then x/y\n\t'];
            format = [format, 'else if (abs_int(y) > abs_int(x)) then 0 \n\t'];
            format = [format, 'else if (x>0) then x/y \n\t'];
            format = [format, 'else (-x)/(-y);\ntel\n\n'];
            node = sprintf(format);
        end
        
        %% fmod, rem, mod
        function [node, external_nodes_i, opens] = get_fmod()
            opens = {'lustrec_math'};
            external_nodes_i = {};
            node = '';
        end
        function [node, external_nodes_i, opens] = get_rem_int_int()
            opens = {};
            external_nodes_i = {};
            format = 'node rem_int_int (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z = if (y = 0 or x = 0) then 0\n\t\telse\n\t\t (x mod y) - (if (x mod y <> 0 and x <= 0) then (if y > 0 then y else -y) else 0);\ntel\n\n'];
            
            node = sprintf(format);
        end
        function [node, external_nodes_i, opens] = get_mod_int_int()
            opens = {};
            external_nodes_i = {};
            format = 'node mod_int_int (x, y: int)\nreturns(z:int);\nlet\n\t';
            format = [format, 'z = if (y = 0) then x else if (x = 0) then 0\n\t\telse\n\t\t (x mod y) - (if (x mod y <> 0 and y <= 0) then (if y > 0 then y else -y) else 0);\ntel\n\n'];
            
            node = sprintf(format);
        end

    end
    
end

