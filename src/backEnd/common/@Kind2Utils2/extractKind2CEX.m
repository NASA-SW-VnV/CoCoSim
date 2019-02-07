%% run compositional modular verification usin Kind2
function [valid, IN_struct] = extractKind2CEX(...
    verif_lus_path,...
    output_dir,...
    node, ...
    OPTS, KIND2, Z3)

    IN_struct = [];
    valid = -1;
    if nargin < 1
        error('Missing arguments to function call: Kind2Utils2.extractKind2CEX')
    end
    if ~exist('OPTS', 'var')
        OPTS = '';
    end
    if ~exist('KIND2', 'var') || ~exist('Z3', 'var')
        tools_config;
        status = BUtils.check_files_exist(KIND2, Z3);
        if status
            display_msg(['KIND2 or Z3 not found :' KIND2 ', ' Z3],...
                MsgType.DEBUG, 'LustrecUtils.run_verif', '');
            return;
        end
    end

    [file_dir, file_name, ~] = fileparts(verif_lus_path);
    if nargin < 2 || isempty(output_dir)
        output_dir = file_dir;
    end

    PWD = pwd;
    cd(output_dir);
    [status, solver_output] = Kind2Utils2.runKIND2(...
        verif_lus_path,...
        node, ...
        OPTS, KIND2, Z3);
    if status
        return;
    end
    [valid, IN_struct] = ...
        Kind2Utils2.extract_Kind2_Comp_Verif_answer(...
        verif_lus_path, ...
        solver_output,...
        file_name,  output_dir);

    cd(PWD);

end
