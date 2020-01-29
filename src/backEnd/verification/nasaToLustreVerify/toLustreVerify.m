function [ failed ] = toLustreVerify(model_full_path,  const_files, lus_backend, varargin)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    global KIND2 Z3;
    if isempty(KIND2)
        tools_config;
    end
    if LusBackendType.isKIND2(lus_backend) && ~exist(KIND2,'file')
        errordlg(sprintf('KIND2 model checker is not found in %s. Please set KIND2 path in tools_config.m', KIND2));
        return;
    elseif ~LusBackendType.isKIND2(lus_backend)
        errordlg('Only KIND2 currently is supported for NASA compiler. To change compiler or Lustre model checker go to Tools -> CoCoSim -> Preferences');
        return;
    end
    if nargin < 2 || isempty(const_files)
        const_files = {};
    end
    if nargin < 3 || isempty(lus_backend)
        lus_backend = LusBackendType.KIND2;
    end

    % Get start time
    t_start = tic;
    %% run ToLustre
    [nom_lustre_file, xml_trace, failed, ~, ...
        ~, pp_model_full_path] = ...
        nasa_toLustre.ToLustre(model_full_path, const_files,...
        lus_backend, CoCoBackendType.VERIFICATION, varargin);

    if failed 
        return;
    end




    %% Get the list of verification blocks: Assertion, Proof Objective, Contracts, Observers.
    load_system(pp_model_full_path);
    [~, model, ~] = fileparts(pp_model_full_path);
    top_node_name = model;
    Assertions_list = find_system(model, ...
        'LookUnderMasks', 'all', 'BlockType','Assertion');
    if ~isempty(Assertions_list)
        enableParams = get_param(Assertions_list, 'Enabled');
        Assertions_list = Assertions_list(strcmp(enableParams, 'on'));
    end
    
    ProofObjective_list = find_system(model, ...
        'LookUnderMasks', 'all', 'MaskType', 'Design Verifier Proof Objective');
    if ~isempty(ProofObjective_list)
        enableParams = get_param(ProofObjective_list, 'enabled');
        ProofObjective_list = ProofObjective_list(strcmp(enableParams, 'on'));
    end
    Assertions_list = [Assertions_list; ProofObjective_list];
    
    Observers = find_system(model, ...
        'LookUnderMasks', 'all', 'MaskType', 'Observer');
%     Assertions_list = [Assertions_list; Observers];
    
    contractBlocks_list = find_system(model, ...
        'LookUnderMasks', 'all',  'MaskType', 'ContractBlock');

    if LusBackendType.isKIND2(lus_backend)
        if ~isempty(Assertions_list) && ~isempty(contractBlocks_list)
            display_msg('Having both Assertion/Proof blocks and contracts are not supported in KIND2.', MsgType.ERROR, 'toLustreVerify', '');
            return;
        end
        CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
        if isfield(CoCoSimPreferences, 'verificationTimeout')
            timeout = CoCoSimPreferences.verificationTimeout;
        else
            timeout = 120;
        end
        if ~isempty(Assertions_list)
            OPTS = ' --slice_nodes false --check_subproperties true ';
            timeout_analysis = timeout / numel(Assertions_list);
        elseif ~isempty(contractBlocks_list)
            if CoCoSimPreferences.compositionalAnalysis
                OPTS = '--modular true --compositional true';
            else
                OPTS = '--modular true';
            end
            timeout_analysis = timeout / numel(contractBlocks_list);
        else
            display_msg('No Property to check.', MsgType.RESULT, 'toLustreVerify', '');
            return;
        end
        tkind2_start = tic;
        [failed, kind2_out] = Kind2Utils2.runKIND2(...
            nom_lustre_file,...
            top_node_name, ...
            OPTS, KIND2, Z3, timeout, timeout_analysis);
        tkind2_finish = toc(tkind2_start);
        if failed
            return;
        end
        display_msg(sprintf('Total KIND2 running time: %f seconds', tkind2_finish), Constants.RESULT, 'Time', '');
        % sometimes kind2 give up quickly and give everything as UNKNOWN. 
        % and we get better results in the second run so we run it twice.
        if tkind2_finish < 10 ...
                && MatlabUtils.contains(kind2_out, 'unknown</Answer>') ...
                && ~MatlabUtils.contains(kind2_out, 'falsifiable</Answer>') ...
                && ~MatlabUtils.contains(kind2_out, 'valid</Answer>')
            display_msg('Re-running Kind2', MsgType.INFO, 'toLustreVerify', '');
            [failed, kind2_out] = Kind2Utils2.runKIND2(...
                nom_lustre_file,...
                top_node_name, ...
                OPTS, KIND2, Z3, timeout, timeout_analysis);
            if failed, return; end
        end
        % Sometimes the Initial state is unsat
        if MatlabUtils.contains(kind2_out, 'the system has no reachable states')
            display_msg('The system has no reachable states.', MsgType.ERROR, 'toLustreVerify', '');
        end
        mapping_file = xml_trace.json_file_path;
        try
            failed = cocoSpecKind2(nom_lustre_file, mapping_file, kind2_out);
            if failed
                return;
            end
            VerificationMenu.displayHtmlVerificationResultsCallbackCode(model)
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'toLustreVerify', '');
            display_msg('Something went wrong in Verification.', MsgType.ERROR, 'toLustreVerify', '');
        end

    else
        if ~isempty(Assertions_list)
            display_msg('Verification of Assertion blocks is only supported by KIND2 model checker.', MsgType.ERROR, 'toLustreVerify', '');
        end
        if ~isempty(contractBlocks_list)
            display_msg('Verification of Contracts blocks is only supported by KIND2 model checker.', MsgType.ERROR, 'toLustreVerify', '');
        end
    end



    %% Generate final report.

    t_finish = toc(t_start);
    display_msg(sprintf('Total verification time: %f seconds', t_finish), Constants.RESULT, 'Time', '');
end
