%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
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
        
        function [node, external_nodes_i, opens, abstractedNodes] = template(lus_backend)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            node = '';
        end
        
        %% Clocks
        function [node, external_nodes_i, opens, abstractedNodes] = get__make_clock(varargin)
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            % format = 'node _make_clock(period: int; phase: int)\nreturns( clk: bool );\nvar count: int;\n';
            % format = [format, 'let\n\t'];
            % format = [format, 'cnt   = ((period - phase) -> (pre(count) + 1)) mod period ;\n\t'];
            % format = [format, 'clk =  (count = 0)  ;\n'];
            % format = [format, 'tel\n'];
            % node = sprintf(format);
            bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('count'), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD, ...  
                            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS, ...
                                                    nasa_toLustre.lustreAst.VarIdExpr('period'),...
                                                    nasa_toLustre.lustreAst.VarIdExpr('phase')), ...
                                         nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                                                    nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                                                         nasa_toLustre.lustreAst.VarIdExpr('count')),...
                                                    nasa_toLustre.lustreAst.IntExpr(1))), ...
                             nasa_toLustre.lustreAst.VarIdExpr('period')));
            bodyElts{2} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('clk'), ...    
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
                        nasa_toLustre.lustreAst.VarIdExpr('count'),...
                        nasa_toLustre.lustreAst.IntExpr(0)));
            node = nasa_toLustre.lustreAst.LustreNode();
            node.setName('_make_clock');
            node.setInputs({nasa_toLustre.lustreAst.LustreVar('period', 'int'), ...
                nasa_toLustre.lustreAst.LustreVar('phase', 'int')});
            node.setOutputs(nasa_toLustre.lustreAst.LustreVar('clk', 'bool'));
            node.setLocalVars(nasa_toLustre.lustreAst.LustreVar('count', 'int'))
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);      
        end
        
    end
    
end

