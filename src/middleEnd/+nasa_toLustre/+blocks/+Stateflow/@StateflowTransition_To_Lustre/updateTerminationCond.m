
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [Termination_cond, body, outputs, variables] = ...
        updateTerminationCond(Termination_cond, condName, trans_cond, ...
        body, outputs, variables, addToVariables)
    
    if addToVariables
        if nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(condName, variables)
            i = 1;
            new_condName = strcat(condName, num2str(i));
            while(nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(new_condName, variables))
                i = i + 1;
                new_condName = strcat(condName, num2str(i));
            end
            condName = new_condName;
        end
    end
    if isempty(Termination_cond)
        if isempty(trans_cond)
            body{end+1} = ...
                nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(condName), nasa_toLustre.lustreAst.BooleanExpr('true'));
        else
            body{end+1} = ...
                nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(condName), trans_cond);
        end
    else
        if isempty(trans_cond)
            body{end+1} = ...
                nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(condName), nasa_toLustre.lustreAst.BooleanExpr('true'));
        else
            body{end+1} = ...
                nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(condName), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.OR, Termination_cond, trans_cond));
        end
    end
    Termination_cond = nasa_toLustre.lustreAst.VarIdExpr(condName);
    if addToVariables
        variables{end+1} = nasa_toLustre.lustreAst.LustreVar(condName, 'bool');
    else
        outputs{end+1} = nasa_toLustre.lustreAst.LustreVar(condName, 'bool');
    end
end

