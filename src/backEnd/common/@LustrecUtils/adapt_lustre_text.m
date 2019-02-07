
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

