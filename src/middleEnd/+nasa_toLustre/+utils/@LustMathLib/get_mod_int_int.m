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
function [node, external_nodes_i, opens, abstractedNodes] = get_mod_int_int(varargin)
        opens = {};
    abstractedNodes = {};
    external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
    % format = 'node mod_int_int (x, y: int)\nreturns(z:int);\nlet\n\t';
    % format = [format, 'z = if (y = 0 or x = 0) then x\n\t\telse\n\t\t (x mod y) - (if (x mod y <> 0 and y <= 0) then (if y > 0 then y else -y) else 0);\ntel\n\n'];
    % node = sprintf(format);
    cond = nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.OR, ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, nasa_toLustre.lustreAst.VarIdExpr('y'), nasa_toLustre.lustreAst.IntExpr(0)), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr(0)));
    cond2 = nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.AND, ...
        nasa_toLustre.lustreAst.BinaryExpr( nasa_toLustre.lustreAst.BinaryExpr.NEQ,...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.VarIdExpr('y')),...
        nasa_toLustre.lustreAst.IntExpr(0)), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LTE, nasa_toLustre.lustreAst.VarIdExpr('y'), nasa_toLustre.lustreAst.IntExpr(0)));
    elseExp =  nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.MINUS, ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.VarIdExpr('y')),...
        nasa_toLustre.lustreAst.IteExpr(cond2, ...
        nasa_toLustre.lustreAst.NodeCallExpr('abs_int',  nasa_toLustre.lustreAst.VarIdExpr('y')),...
        nasa_toLustre.lustreAst.IntExpr(0),...
        true)...
        );
    rhs = nasa_toLustre.lustreAst.IteExpr(cond, nasa_toLustre.lustreAst.VarIdExpr('x'), elseExp);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('z'), ...
        rhs...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName('mod_int_int');
    node.setInputs({nasa_toLustre.lustreAst.LustreVar('x', 'int'), nasa_toLustre.lustreAst.LustreVar('y', 'int')});
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('z', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
