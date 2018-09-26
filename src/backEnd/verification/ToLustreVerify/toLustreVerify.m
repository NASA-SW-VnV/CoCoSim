function [ ] = toLustreVerify(model_full_path,  const_files, backend, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('const_files', 'var') || isempty(const_files)
    const_files = {};
end
if ~exist('backend', 'var') || isempty(backend)
    backend = BackendType.KIND2;
end


%% run ToLustre
[nom_lustre_file, xml_trace, status, unsupportedOptions, ...
    abstractedBlocks, pp_model_full_path] = ...
    ToLustre(model_full_path, const_files,...
    backend, varargin);

if status || ~isempty(unsupportedOptions)
    return;
end
if BackendType.isKIND2(backend)
    tools_config;
    [status, output] = Kind2Utils2.checkSyntaxError(nom_lustre_file, KIND2, Z3);
    if status
        display_msg('Simulink To Lustre has failed.', MsgType.ERROR, 'toLustreVerify', '');
        display_msg(output, MsgType.DEBUG, 'toLustreVerify', '');
        return;
    end
end
% Get start time
t_start = now;


%% Get the list of verification blocks: Assertion, Proof Objective, Contracts, Observers.
load_system(pp_model_full_path);
[~, model, ~] = fileparts(pp_model_full_path);
Assertions_list = find_system(model, ...
    'LookUnderMasks', 'all', 'BlockType','Assertion');
ProofObjective_list = find_system(model, ...
    'LookUnderMasks', 'all', 'MaskType', 'Design Verifier Proof Objective');
Assertions_list = [Assertions_list; ProofObjective_list];
contractBlocks_list = find_system(model, ...
    'LookUnderMasks', 'all',  'MaskType', 'ContractBlock');

if BackendType.isKIND2(backend)
    
    
else
    if ~isempty(Assertions_list)
        display_msg('Verification of Assertion blocks is only supported by KIND2 model checker.', MsgType.ERROR, 'toLustreVerify', '');
    end
    if ~isempty(contractBlocks_list)
        display_msg('Verification of Assertion blocks is only supported by KIND2 model checker.', MsgType.ERROR, 'toLustreVerify', '');
    end
end



%% Generate final report.

t_end = now;
t_compute = t_end - t_start;
display_msg(['Total verification time: ' datestr(t_compute, 'HH:MM:SS.FFF')], Constants.RESULT, 'Time', '');
end
