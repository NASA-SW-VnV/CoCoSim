function new_obj = simplify(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
        new_args = cellfun(@(x) x.simplify(), obj.args, 'UniformOutput', 0);
    % remove parentheses from arguments.
    for i=1:numel(new_args)
        if isa(new_args{i}, 'nasa_toLustre.lustreAst.ParenthesesExpr')
            new_args{i} = new_args{i}.getExp();
        elseif isa(new_args{i}, 'nasa_toLustre.lustreAst.BinaryExpr') || isa(new_args{i}, 'nasa_toLustre.lustreAst.UnaryExpr')
            new_args{i}.setPar(false);
        end
    end
    new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
end
