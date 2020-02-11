%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        
        %% __time_step = (0.0 -> ((pre (__time_step)) + dt));
        function [node, external_nodes_i, opens, abstractedNodes] = get_getTimeStep(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            y_id = nasa_toLustre.utils.SLX2LusUtils.timeStepStr();
            bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
                nasa_toLustre.lustreAst.VarIdExpr(y_id), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                nasa_toLustre.lustreAst.RealExpr('0.0'), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                nasa_toLustre.lustreAst.UnaryExpr(...
                nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                nasa_toLustre.lustreAst.VarIdExpr(y_id)), ...
                nasa_toLustre.lustreAst.VarIdExpr('dt'))));
            node = nasa_toLustre.lustreAst.LustreNode();
            node.setName('getTimeStep');
            node.setInputs({nasa_toLustre.lustreAst.LustreVar('dt', 'real')});
            node.setOutputs(nasa_toLustre.lustreAst.LustreVar(y_id, 'real'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
        end
        %% __nb_step  = (0 -> ((pre (__nb_step )) + 1));
        function [node, external_nodes_i, opens, abstractedNodes] = get_getNbStep(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            y_id = nasa_toLustre.utils.SLX2LusUtils.nbStepStr();
            bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
                nasa_toLustre.lustreAst.VarIdExpr(y_id), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                nasa_toLustre.lustreAst.IntExpr(0), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                nasa_toLustre.lustreAst.UnaryExpr(...
                nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                nasa_toLustre.lustreAst.VarIdExpr(y_id)), ...
                nasa_toLustre.lustreAst.IntExpr(1))));
            node = nasa_toLustre.lustreAst.LustreNode();
            node.setName('getNbStep');
            node.setInputs({nasa_toLustre.lustreAst.LustreVar('_virtual', 'bool')});
            node.setOutputs(nasa_toLustre.lustreAst.LustreVar(y_id, 'int'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
        end
    end
    
end

