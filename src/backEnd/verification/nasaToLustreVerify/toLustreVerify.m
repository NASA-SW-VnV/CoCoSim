%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ failed ] = toLustreVerify(model_full_path,  const_files, lus_backend, varargin)

    global KIND2 Z3;
    if isempty(KIND2)
        tools_config;
    end
    if coco_nasa_utils.LusBackendType.isKIND2(lus_backend) && ~exist(KIND2,'file')
        errordlg(sprintf(['KIND2 model checker is not found in "%s".\n'...
            'Please set KIND2 path in tools_config.m script under tools folder.\n'...
            'If you want to generate Lustre code for verification, '...
            'do tools -> CoCoSim -> Generate code -> Lustre -> For Verification.'], KIND2));
        return;
    elseif ~coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
        errordlg(['Only KIND2 currently is supported for NASA compiler. '...
            'To change compiler or Lustre model checker go to '...
            'Tools -> CoCoSim -> Preferences -> Simulink to Lustre Compiler.']);
        return;
    end
    if nargin < 2 || isempty(const_files)
        const_files = {};
    end
    if nargin < 3 || isempty(lus_backend)
        lus_backend = coco_nasa_utils.LusBackendType.KIND2;
    end

    % Get start time
    t_start = tic;
    %% run ToLustre
    [nom_lustre_file, xml_trace, failed, ~, ...
        ~, pp_model_full_path] = ...
        nasa_toLustre.ToLustre(model_full_path, const_files,...
        lus_backend, coco_nasa_utils.CoCoBackendType.VERIFICATION, varargin);

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

    if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
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
                && coco_nasa_utils.MatlabUtils.contains(kind2_out, 'unknown</Answer>') ...
                && ~coco_nasa_utils.MatlabUtils.contains(kind2_out, 'falsifiable</Answer>') ...
                && ~coco_nasa_utils.MatlabUtils.contains(kind2_out, 'valid</Answer>')
            display_msg('Re-running Kind2', MsgType.INFO, 'toLustreVerify', '');
            [failed, kind2_out] = Kind2Utils2.runKIND2(...
                nom_lustre_file,...
                top_node_name, ...
                OPTS, KIND2, Z3, timeout, timeout_analysis);
            if failed, return; end
        end
        % Sometimes the Initial state is unsat
        if coco_nasa_utils.MatlabUtils.contains(kind2_out, 'the system has no reachable states')
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
