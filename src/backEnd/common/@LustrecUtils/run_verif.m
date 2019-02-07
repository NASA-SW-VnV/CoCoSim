
%% run Zustre or kind2 on verification file
function [answer, IN_struct, time_max] = run_verif(...
        verif_lus_path,...
        inports, ...
        output_dir,...
        node_name,...
        Backend)
    IN_struct = [];
    time_max = 0;
    answer = '';
    if nargin < 1
        error('Missing arguments to function call: LustrecUtils.run_verif')
    end
    [file_dir, file_name, ~] = fileparts(verif_lus_path);
    if nargin < 3 || isempty(output_dir)
        output_dir = file_dir;
    end
    if nargin < 4 || isempty(node_name)
        node_name = 'top';
    end
    if nargin < 5 || isempty(Backend)
        Backend = 'KIND2';
    end
    timeout = '600';
    cd(output_dir);
    tools_config;

    if strcmp(Backend, 'ZUSTRE') || strcmp(Backend, 'Z')
        status = BUtils.check_files_exist(ZUSTRE);
        if status
            return;
        end
        command = sprintf('%s "%s" --node %s --xml  --matlab --timeout %s --save ',...
            ZUSTRE, verif_lus_path, node_name, timeout);
        display_msg(['ZUSTRE_COMMAND ' command],...
            MsgType.DEBUG,...
            'LustrecUtils.run_verif',...
            '');

    elseif strcmp(Backend, 'KIND2') || strcmp(Backend, 'K')
        status = BUtils.check_files_exist(KIND2, Z3);
        if status
            return;
        end
        command = sprintf('%s --z3_bin %s -xml --timeout %s --lus_main %s "%s"',...
            KIND2, Z3, timeout, node_name, verif_lus_path);
        display_msg(['KIND2_COMMAND ' command],...
            MsgType.DEBUG, 'LustrecUtils.run_verif', '');

    end
    [~, solver_output] = system(command);
    display_msg(...
        solver_output,...
        MsgType.DEBUG,...
        'LustrecUtils.run_verif',...
        '');
    [answer, CEX_XML] = ...
        LustrecUtils.extract_answer(...
        solver_output,...
        Backend,  file_name, node_name,  output_dir);
    if strcmp(answer, 'UNSAFE') && ~isempty(CEX_XML)
        [IN_struct, time_max] =...
            LustrecUtils.cexTostruct(CEX_XML, node_name, inports);
    end

end

