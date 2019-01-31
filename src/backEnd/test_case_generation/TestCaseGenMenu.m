%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = TestCaseGenMenu(varargin)
schema = sl_container_schema;
schema.label = 'Test-case generation using ...';
schema.statustip = 'Generate Lustre code';
schema.autoDisableWhen = 'Busy';

schema.childrenFcns = {@MCDC,@Mutation , @Random};
end

%%
function schema = Random(varargin)
schema = sl_action_schema;
schema.label = 'Random testing';
schema.callback = @RandomCallback;
end

function RandomCallback(varargin)
try
    model_full_path = MenuUtils.get_file_name(gcs);
    MenuUtils.add_pp_warning(model_full_path);
    random_test_gui('model_full_path',model_full_path);
catch ME
    MenuUtils.handleExceptionMessage(ME, 'Test-case generation');
end
end

%%
function schema = Mutation(varargin)
schema = sl_action_schema;
schema.label = 'Mutation based testing';
schema.callback = @MutationCallback;
end

function MutationCallback(varargin)
try
    model_full_path = MenuUtils.get_file_name(gcs);
    MenuUtils.add_pp_warning(model_full_path);
    mutation_test_gui('model_full_path',model_full_path);
catch ME
    MenuUtils.handleExceptionMessage(ME, 'Test-case generation');
end
end

%%
function schema = MCDC(varargin)
schema = sl_action_schema;
schema.label = 'MC-DC coverage';
schema.callback = @MCDCCallback;
end

function MCDCCallback(varargin)
try
    model_full_path = MenuUtils.get_file_name(gcs);
    MenuUtils.add_pp_warning(model_full_path);
    mcdc_test_gui('model_full_path',model_full_path);
catch ME
    MenuUtils.handleExceptionMessage(ME, 'Test-case generation');
end
end
