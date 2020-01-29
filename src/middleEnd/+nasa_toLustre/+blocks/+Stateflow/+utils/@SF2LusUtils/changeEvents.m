%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function call = changeEvents(call, EventsNames, E)
    
    args = call.getArgs();
    inputs_Ids = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.getId()), ...
        args, 'UniformOutput', false);
    for i=1:numel(inputs_Ids)
        if strcmp(inputs_Ids{i}.getId(), E)
            inputs_Ids{i} = nasa_toLustre.lustreAst.BoolExpr(true);
        elseif ismember(inputs_Ids{i}.getId(), EventsNames)
            inputs_Ids{i} = nasa_toLustre.lustreAst.BoolExpr(false);
        end
    end

    call = nasa_toLustre.lustreAst.NodeCallExpr(call.nodeName, inputs_Ids);
end
