%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% run kind2 with arguments
function [status, solver_output] = runKIND2(...
    verif_lus_path,...
    node, ...
    OPTS, KIND2, Z3, timeout, timeout_analysis)

    status = 0;

    if nargin < 1
        error('Missing arguments to function call: Kind2Utils2.runKIND2')
    end
    %

    %
    if ~exist('OPTS', 'var')
        OPTS = '';
    end
    if nargin >= 2 && ~isempty(node)
        OPTS = sprintf('%s --lus_main %s', OPTS, node);
    end
    if nargin >= 7 && ~isempty(timeout_analysis)
        OPTS = sprintf('%s --timeout_analysis %d', OPTS, timeout_analysis);
    end
    %
    if nargin < 4
        tools_config;
        status = BUtils.check_files_exist(KIND2, Z3);
        if status
            display_msg(['KIND2 or Z3 not found :' KIND2 ', ' Z3],...
                MsgType.DEBUG, 'LustrecUtils.run_verif', '');
            return;
        end
    end
    %
    if ~exist('timeout', 'var') || isempty(timeout)
        CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
        if isfield(CoCoSimPreferences, 'verificationTimeout')
            timeout = num2str(CoCoSimPreferences.verificationTimeout);
        else
            timeout = '120';
        end
    elseif isnumeric(timeout)
        timeout = num2str(timeout);
    end

    command = sprintf('%s -xml  --z3_bin %s --timeout %s %s "%s"',...
        KIND2, Z3, timeout, OPTS,  verif_lus_path);
    display_msg(['KIND2_COMMAND ' command],...
        MsgType.DEBUG, 'Kind2Utils2.run_verif', '');

    [~, solver_output] = system(command, '-echo' );
    display_msg(...
        solver_output,...
        MsgType.DEBUG,...
        'Kind2Utils2.run_verif',...
        '');

end
