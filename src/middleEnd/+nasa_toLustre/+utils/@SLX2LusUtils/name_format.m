
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% adapt blocks names to be a valid lustre names.
function str_out = name_format(str)
    str_out = strrep(str, newline, '');
    str_out = regexprep(str_out, '^\s', '_');
    str_out = regexprep(str_out, '\s$', '_');
    str_out = strrep(str_out, ' ', '');
    str_out = strrep(str_out, '-', '_minus_');
    str_out = strrep(str_out, '+', '_plus_');
    str_out = strrep(str_out, '*', '_mult_');
    str_out = strrep(str_out, '>', '_gt_');
    str_out = strrep(str_out, '>=', '_gte_');
    str_out = strrep(str_out, '<', '_lt_');
    str_out = strrep(str_out, '<=', '_lte_');
    str_out = strrep(str_out, '.', '_dot_');
    str_out = strrep(str_out, '#', '_sharp_');
    str_out = strrep(str_out, '(', '_lpar_');
    str_out = strrep(str_out, ')', '_rpar_');
    str_out = strrep(str_out, '[', '_lsbrak_');
    str_out = strrep(str_out, ']', '_rsbrak_');
    str_out = strrep(str_out, '{', '_lbrak_');
    str_out = strrep(str_out, '}', '_rbrak_');
    str_out = strrep(str_out, ',', '_comma_');
    %             str_out = strrep(str_out, '/', '_slash_');
    str_out = strrep(str_out, '=', '_equal_');
    % for blocks starting with a digit.
    str_out = regexprep(str_out, '^(\d+)', 'x$1');
    str_out = regexprep(str_out, '/(\d+)', '/_$1');
    % for anything missing from previous cases.
    str_out = regexprep(str_out, '[^a-zA-Z0-9_/]', '_');
end

