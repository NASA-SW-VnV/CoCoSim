%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = generateInvariantsMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Generate Invariants (Experimental)';
schema.statustip = 'Generate the invariants used for safe properties';
schema.autoDisableWhen = 'Busy';

schema.childrenFcns = {@zustreInvariantsMenu};
end

function schema = zustreInvariantsMenu(callbackInfo)
schema = sl_action_schema;
schema.label = 'Zustre';
schema.callback = @zustreInvCallback;
end


function zustreInvCallback(callbackInfo)
model_full_path = MenuUtils.get_file_name(gcs);
simulink_name = gcs;
contract_name = [simulink_name '_COCOSPEC'];
emf_name = [simulink_name '_EMF'];
try
    CONTRACT = evalin('base', contract_name);
    EMF = evalin('base', emf_name);
    disp(['CONTRACT LOCATION ' char(CONTRACT)])
    
catch ME
    display_msg(ME.getReport(),Constants.DEBUG,'viewContract','');
    msg = sprintf('No CoCoSpec Contract for %s \n. First verify the model with Zustre', simulink_name);
    warndlg(msg,'CoCoSim: Warning');
    return;
end
try
    Output_url = generate_invariants_Zustre(model_full_path, char(EMF));
    open(Output_url);
catch ME
    display_msg(ME.getReport(),Constants.DEBUG,'viewContract','');
end
end