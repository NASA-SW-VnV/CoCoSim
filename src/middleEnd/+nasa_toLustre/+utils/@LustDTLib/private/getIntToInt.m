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
function [node, external_nodes, opens, abstractedNodes] = getIntToInt(dt)

    global CoCoSimPreferences
    if isempty(CoCoSimPreferences)
        CoCoSimPreferences.forceTypeCastingOfInt = true;
    end
    opens = {};
    abstractedNodes = {};
    external_nodes = {};
    v_max = double(intmax(dt));% we need v_max as double variable
    v_min = double(intmin(dt));% we need v_min as double variable
    nb_int = (v_max - v_min + 1);
    node_name = strcat('int_to_', dt);
    
    % format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
    % format = [format, 'y= if x > v_max then v_min + rem_int_int((x - v_max - 1),nb_int) \n\t'];
    % format = [format, 'else if x < v_min then v_max + rem_int_int((x - (v_min) + 1),nb_int) \n\telse x;\ntel\n\n'];
    % node = sprintf(format, node_name, v_max, v_min, v_max, nb_int,...
    %     v_min, v_max, v_min, nb_int);
    if CoCoSimPreferences.forceTypeCastingOfInt
        conds{1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, ...
            nasa_toLustre.lustreAst.VarIdExpr('x'), ...
            nasa_toLustre.lustreAst.IntExpr(v_max));
        conds{2} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, ...
            nasa_toLustre.lustreAst.VarIdExpr('x'), ...
            nasa_toLustre.lustreAst.IntExpr(v_min));
        %  %d + rem_int_int((x - %d - 1),%d)
        thens{1} = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
            nasa_toLustre.lustreAst.IntExpr(v_min),...
            nasa_toLustre.lustreAst.NodeCallExpr('rem_int_int',...
            {nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
            {nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr(v_max), nasa_toLustre.lustreAst.IntExpr(1)}),...
            nasa_toLustre.lustreAst.IntExpr(nb_int)}));
        %d + rem_int_int((x - (%d) + 1),%d)
        if v_min == 0, neg_vmin = 0; else, neg_vmin = -v_min; end
        thens{2} = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
            nasa_toLustre.lustreAst.IntExpr(v_max),...
            nasa_toLustre.lustreAst.NodeCallExpr('rem_int_int', ...
            {nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
            {nasa_toLustre.lustreAst.VarIdExpr('x'),...
            nasa_toLustre.lustreAst.IntExpr(neg_vmin),...
            nasa_toLustre.lustreAst.IntExpr(1)}),...
            nasa_toLustre.lustreAst.IntExpr(nb_int)}));
        thens{3} = nasa_toLustre.lustreAst.VarIdExpr('x');
        bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.VarIdExpr('y'), ...
            nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
        external_nodes = {strcat('LustMathLib_', 'rem_int_int')};
        
    else
        bodyElts{1} = nasa_toLustre.lustreAst.LustreComment('Type-casting was disabled. See Tools -> CoCoSim -> Preferences -> NASA compiler preferences.');
        bodyElts{2} =   nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.VarIdExpr('y'), ...
            nasa_toLustre.lustreAst.VarIdExpr('x'));
        
    end
    
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'int'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    
    
end
