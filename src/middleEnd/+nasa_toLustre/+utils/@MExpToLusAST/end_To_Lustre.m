function [code, exp_dt, dim, extra_code] = end_To_Lustre(tree, args)
    % end is used for Array indexing: e.g., x(end-1), x(1:end) ... 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    
    code = {};
    exp_dt = 'int';
    dim = [1 1];
    extra_code = {};
    if isfield(args, 'end_value')
        code{1} = nasa_toLustre.lustreAst.IntExpr(args.end_value);
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            '"end" can not be used in indexing in Block %s',...
            args.blk.Origin_path);
        throw(ME);
    end
end
