%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [tree, expr] = parseVar(expr)
    regex = '^[A-Za-z0-9_]+';
    match = regexp(expr, regex, 'match', 'once');
    if ~isempty(match)
        tree = match;
        expr = regexprep(expr, regex,'');
    else
        tree = '';
    end
end

