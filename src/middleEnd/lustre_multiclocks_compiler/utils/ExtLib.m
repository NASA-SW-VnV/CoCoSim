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
        
        function [node, external_nodes_i, opens] = template(varargin)
            opens = {};
            external_nodes_i = {};
            node = '';
        end
        
        %% Clocks
        function [node, external_nodes_i, opens] = get__make_clock(varargin)
            opens = {};
            external_nodes_i = {};
            % format = 'node _make_clock(period: int; phase: int)\nreturns( clk: bool );\nvar count: int;\n';
            % format = [format, 'let\n\t'];
            % format = [format, 'cnt   = ((period - phase) -> (pre(count) + 1)) mod period ;\n\t'];
            % format = [format, 'clk =  (count = 0)  ;\n'];
            % format = [format, 'tel\n'];
            % node = sprintf(format);
            bodyElts{1} = LustreEq(VarIdExpr('count'), ...
                BinaryExpr(BinaryExpr.MOD, ...  
                            BinaryExpr(BinaryExpr.ARROW, ...
                                        BinaryExpr(BinaryExpr.MINUS, ...
                                                    VarIdExpr('period'),...
                                                    VarIdExpr('phase')), ...
                                         BinaryExpr(BinaryExpr.PLUS, ...
                                                    UnaryExpr(UnaryExpr.PRE, ...
                                                         VarIdExpr('count')),...
                                                    IntExpr(1))), ...
                             VarIdExpr('period')));
            bodyElts{2} = LustreEq(VarIdExpr('clk'), ...    
                BinaryExpr(BinaryExpr.EQ, ...
                        VarIdExpr('count'),...
                        IntExpr(0)));
            node = LustreNode();
            node.setName('_make_clock');
            node.setInputs({LustreVar('period', 'int'), ...
                LustreVar('phase', 'int')});
            node.setOutputs(LustreVar('clk', 'bool'));
            node.setLocalVars(LustreVar('count', 'int'))
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);      
        end
        
    end
    
end

