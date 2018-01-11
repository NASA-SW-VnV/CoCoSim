%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = TestCaseGenMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Test-case generation using ...';
schema.statustip = 'Generate Lustre code';
schema.autoDisableWhen = 'Busy';

schema.childrenFcns = {@Mutation, @MCDC};
end


function schema = Mutation(callbackInfo)
schema = sl_action_schema;
schema.label = 'Mutation based testing';
schema.callback = @MutationCallback;
end

function MutationCallback(callbackInfo)
msgbox('Not implemented yet')
end

function schema = MCDC(callbackInfo)
schema = sl_action_schema;
schema.label = 'MC-DC coverage';
schema.callback = @MCDCCallback;
end

function MCDCCallback(callbackInfo)
msgbox('Not implemented yet')
end
