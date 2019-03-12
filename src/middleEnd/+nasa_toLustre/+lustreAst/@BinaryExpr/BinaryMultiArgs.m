function exp = BinaryMultiArgs(op, args, isFirstTime)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Given many args, this function return the binary operation
% applied on all arguments.
    
    
    if nargin < 3
        isFirstTime = 1;
    end
    if isempty(args) || numel(args) == 1
        if iscell(args)
            exp = args{1};
        else
            exp = args;
        end
    elseif numel(args) == 2
        exp = nasa_toLustre.lustreAst.BinaryExpr(op, ...
            args{1}, ...
            args{2},...
            false);
        if isFirstTime
            exp = nasa_toLustre.lustreAst.ParenthesesExpr(exp);
        end
    else
        exp = nasa_toLustre.lustreAst.BinaryExpr(op, ...
            args{1}, ...
            nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, args(2:end), false), ...
            false);
        if isFirstTime
            exp = nasa_toLustre.lustreAst.ParenthesesExpr(exp);
        end
    end
end


