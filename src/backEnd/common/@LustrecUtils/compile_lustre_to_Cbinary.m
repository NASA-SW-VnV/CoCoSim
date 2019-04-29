%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% compile_lustre_to_Cbinary
function err = compile_lustre_to_Cbinary(lus_file_path, ...
        node_name, ...
        output_dir, ...
        LUSTREC,...
        LUSTREC_OPTS, ...
        LUCTREC_INCLUDE_DIR)
    if nargin < 4
        tools_config;
        err = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
        if err
            msg = sprintf('Binary "%s" and directory "%s" not found ',LUSTREC, LUCTREC_INCLUDE_DIR);
            display_msg(msg, MsgType.ERROR, 'generate_lusi', '');
            return;
        end
    end
    [~, file_name, ~] = fileparts(lus_file_path);

    binary_name = fullfile(output_dir,...
        strcat(file_name,'_', node_name));
    % generate C code
    if BUtils.isLastModified(lus_file_path, binary_name)
        err = 0;
        display_msg(['file ' binary_name ' has been already generated.'],...
            MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        return;
    end
    %-algebraic-loop-solve should be added
    command = sprintf('%s %s -I "%s" -d "%s" -node %s "%s"',...
        LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR, output_dir, node_name, lus_file_path);
    msg = sprintf('LUSTREC_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
    [err, lustre_out] = system(command);
    if err
        display_msg(msg, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        msg = sprintf('lustrec failed for model "%s"',lus_file_path);
        display_msg(msg, MsgType.ERROR, 'compile_lustre_to_Cbinary', '');
        display_msg(msg, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        display_msg(lustre_out, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        err = 1;
        return
    end
    OldPwd = pwd;

    % generate C binary
    cd(output_dir);
    makefile_name = fullfile(output_dir,strcat(file_name,'.makefile'));
    msg = sprintf('start compiling model "%s"\n',file_name);
    display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
    GCC_FLAGS = 'gcc -O0 -Wno-all -fbracket-depth=10000';
    makefile_OPTS = sprintf('BINNAME="%s" GCC="%s"', binary_name, GCC_FLAGS);
    command = sprintf('make %s -f "%s"',makefile_OPTS, makefile_name);
    msg = sprintf('MAKE_LUSTREC_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
    [err, make_out] = system(command);
    if err
        msg = sprintf('Compilation failed for model "%s" ',file_name);
        display_msg(msg, MsgType.ERROR, 'compile_lustre_to_Cbinary', '');
        display_msg(msg, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        display_msg(make_out, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        err = 1;
        cd(OldPwd);
        return
    end

end
