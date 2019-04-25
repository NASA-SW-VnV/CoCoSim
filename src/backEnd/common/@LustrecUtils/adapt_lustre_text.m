%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function t = adapt_lustre_text(t, lusBackend, output_dir)
    if nargin < 2
        lusBackend = '';
    end
    if nargin < 3
        output_dir = '';
    end
    t = regexprep(t, '''', '''''');
    t = regexprep(t, '%', '%%');
    t = regexprep(t, '\\', '\\\');
    t = regexprep(t, '!=', '<>');
    if strcmp(lusBackend, LusBackendType.KIND2)
        t = regexprep(t, '\(\*! /coverage/mcdc/', '(* /coverage/mcdc/');
        t = regexprep(t, '\(\*! PROPERTY:', '(*!PROPERTY');
        nasa_toLustre_path = fileparts(which('nasa_toLustre.ToLustre'));
        lib_path = fullfile(nasa_toLustre_path, '+lib');
        if ~isempty(regexp(t, '#open\s+<conv>', 'match'))
            t = regexprep(t, '#open\s+<conv>', 'include "conv.lus"');
            lus_lib_path = fullfile(lib_path, 'conv.lus');
            copyfile(lus_lib_path, output_dir);
        end
        if ~isempty(regexp(t, '#open\s+<lustrec_math>', 'match'))
            t = regexprep(t, '#open\s+<lustrec_math>', 'include "lustrec_math.lus"');
            lus_lib_path = fullfile(lib_path, 'lustrec_math.lus');
            copyfile(lus_lib_path, output_dir);
        end
        if ~isempty(regexp(t, '#open\s+<simulink_math_fcn>', 'match'))
            t = regexprep(t, '#open\s+<simulink_math_fcn>', 'include "simulink_math_fcn.lus"');
            lus_lib_path = fullfile(lib_path, 'simulink_math_fcn.lus');
            copyfile(lus_lib_path, output_dir);
        end
    end
end

