%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function t = adapt_lustre_text(t, dest)
    if nargin < 2
        dest = '';
    end
    t = regexprep(t, '''', '''''');
    t = regexprep(t, '%', '%%');
    t = regexprep(t, '\\', '\\\');
    t = regexprep(t, '!=', '<>');
    if strcmp(dest, 'Kind2')
        t = regexprep(t, '\(\*! /coverage/mcdc/', '(* /coverage/mcdc/');
    end
end

