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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [delay_node] = getDelayNode(node_name, ...
        u_DT, delayLength, isDelayVariable)

    
    %node header
    [ u_DT, ~ ] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( u_DT);
    node_inputs{1} = nasa_toLustre.lustreAst.LustreVar('u', u_DT);
    node_inputs{2} = nasa_toLustre.lustreAst.LustreVar('x0', u_DT);
    if isDelayVariable
        node_inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar('d', 'int');
    end
    
    pre_u_conds = {};
    pre_u_thens = {};
    if isDelayVariable
        pre_u_conds{end + 1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, ...
            nasa_toLustre.lustreAst.VarIdExpr('d'), nasa_toLustre.lustreAst.IntExpr(1));
        pre_u_thens{end + 1} = nasa_toLustre.lustreAst.VarIdExpr('u');
        pre_u_conds{end + 1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, ...
            nasa_toLustre.lustreAst.VarIdExpr('d'), nasa_toLustre.lustreAst.IntExpr(delayLength));
        pre_u_thens{end + 1} = nasa_toLustre.lustreAst.VarIdExpr('pre_u1');
    end
    variables = cell(1, delayLength);
    body = cell(1, delayLength + 1 );
    for i=1:delayLength
        pre_u_i = sprintf('pre_u%d', i);
        if i< delayLength
            pre_u_i_plus_1 = sprintf('pre_u%d', i+1);
        else
            pre_u_i_plus_1 = 'u';
        end
        enable_then = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
            nasa_toLustre.lustreAst.VarIdExpr(pre_u_i_plus_1));
        enable = enable_then;
        rhs = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            nasa_toLustre.lustreAst.VarIdExpr('x0'), ...
            enable);
        body{i} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(pre_u_i), rhs);
        
        if isDelayVariable
            j = delayLength - i + 1;
            pre_u_conds{end + 1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
                nasa_toLustre.lustreAst.VarIdExpr('d'), nasa_toLustre.lustreAst.IntExpr(i));
            pre_u_thens{end+1} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('pre_u%d', j));
            
        end
        variables{i} = nasa_toLustre.lustreAst.LustreVar(pre_u_i, u_DT);
    end
    if isDelayVariable
        pre_u_thens{end+1} = nasa_toLustre.lustreAst.VarIdExpr('x0');
    else
        pre_u_thens{end+1} = nasa_toLustre.lustreAst.VarIdExpr('pre_u1');
    end
    pre_u_rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(pre_u_conds, pre_u_thens);
    
    pre_u = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('pre_u'), pre_u_rhs);
    body{delayLength + 1} = pre_u;
    outputs = nasa_toLustre.lustreAst.LustreVar('pre_u', u_DT);
    delay_node = nasa_toLustre.lustreAst.LustreNode({},...
        node_name, node_inputs, outputs, ...
        {}, variables, body, false);
end

