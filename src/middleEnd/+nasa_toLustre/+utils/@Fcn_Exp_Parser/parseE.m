%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function [tree, status, expr] = parseE(e)
    status = 0;
    [tree, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEA(e);
    if ~isempty(expr)
        status = 1;
    end
end
