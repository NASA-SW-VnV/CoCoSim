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
function [Termination_cond, body, outputs] = ...
        updateTerminationCond(Termination_cond, varName, trans_cond, ...
        body, outputs, addToOutputs)
    % keep truck of last var counter to speed up the lookup of already defined
    % variables
    %TODO: use hash map for variables instead to speedup the lookup
    
    if isempty(Termination_cond)
        if isempty(trans_cond)
            Termination_cond = nasa_toLustre.lustreAst.BoolExpr('true');
        else
            Termination_cond = trans_cond;
        end
    else
        if isempty(trans_cond)
            Termination_cond = nasa_toLustre.lustreAst.BoolExpr('true');
        else
            Termination_cond = ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.OR, Termination_cond, trans_cond);
        end
    end
    
    if addToOutputs
        % add to outputs of FoundValidPath output
        body{end+1} = ...
            nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(varName), Termination_cond);
        outputs{end+1} = nasa_toLustre.lustreAst.LustreVar(varName, 'bool');
    end
end



function [Termination_cond, body, outputs, variables] = ...
        updateTerminationCondV1(Termination_cond, varName, trans_cond, ...
        body, outputs, variables, addToVariables)
    
    % keep truck of last var counter to speed up the lookup of already defined
    % variables
    %TODO: use hash map for variables instead to speedup the lookup
    persistent vars_counter_map;
    if isempty(vars_counter_map)
        vars_counter_map = containers.Map('KeyType', 'char', 'ValueType', 'uint16');
    end
    if addToVariables
        
        if isKey(vars_counter_map, varName)
            vars_counter_map(varName) = vars_counter_map(varName) + 1;
        else
            vars_counter_map(varName) = 1;
        end
        varName = strcat(varName, num2str(vars_counter_map(varName)));

    end
    if isempty(Termination_cond)
        if isempty(trans_cond)
            body{end+1} = ...
                nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(varName), nasa_toLustre.lustreAst.BoolExpr('true'));
        else
            body{end+1} = ...
                nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(varName), trans_cond);
        end
    else
        if isempty(trans_cond)
            body{end+1} = ...
                nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(varName), nasa_toLustre.lustreAst.BoolExpr('true'));
        else
            body{end+1} = ...
                nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(varName), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.OR, Termination_cond, trans_cond));
        end
    end
    Termination_cond = nasa_toLustre.lustreAst.VarIdExpr(varName);
    if addToVariables
        variables{end+1} = nasa_toLustre.lustreAst.LustreVar(varName, 'bool');
    else
        outputs{end+1} = nasa_toLustre.lustreAst.LustreVar(varName, 'bool');
    end
end

