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
function [ failed ] = run(model_full_path,  const_files, lus_backend, varargin)
    
    global KIND2;
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
    % run ToLustre
    [nom_lustre_file, xml_trace, failed, ~, ...
        ~, pp_model_full_path] = ...
        nasa_toLustre.ToLustre(model_full_path, const_files,...
        lus_backend, coco_nasa_utils.CoCoBackendType.VERIFICATION, varargin);
    
    if failed
        return;
    end
    
    
    
    
    % Get the list of verification blocks: Assertion, Proof Objective, Contracts, Observers.
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
    
    %Observers = find_system(model, ...
    %   'LookUnderMasks', 'all', 'MaskType', 'Observer');
    %     Assertions_list = [Assertions_list; Observers];
    
    contractBlocks_list = find_system(model, ...
        'LookUnderMasks', 'all',  'MaskType', 'ContractBlock');
    
    if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
        failed = coco_nasa_verify.ToLustreVerify.run_kind2(model, nom_lustre_file, xml_trace, ...
            top_node_name, Assertions_list, contractBlocks_list, KIND2);
    else
        if ~isempty(Assertions_list)
            display_msg('Verification of Assertion blocks is only supported by KIND2 model checker.', MsgType.ERROR, 'toLustreVerify.run', '');
        end
        if ~isempty(contractBlocks_list)
            display_msg('Verification of Contracts blocks is only supported by KIND2 model checker.', MsgType.ERROR, 'toLustreVerify.run', '');
        end
    end
    
    
    
    %% Generate final report.
    
    t_finish = toc(t_start);
    display_msg(sprintf('Total verification time: %f seconds', t_finish), Constants.RESULT, 'Time', '');
end


