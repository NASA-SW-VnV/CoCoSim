%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = importLusReqMenu(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Requirements';
    schema.statustip = 'Import/Create Lustre Requirements';
    schema.autoDisableWhen = 'Busy';
    
    schema.childrenFcns = {...
        %@createReqMenu,...
        @importReqMenu};
end

%%
% function schema = createReqMenu(callbackInfo)
% schema = sl_action_schema;
% schema.label = 'Create Requirement';
% schema.callback = @createReqCallback;
% end
%
%
% function createReqCallback(callbackInfo)
% model_full_path = MenuUtils.get_file_name(gcs);
% try
%     createReqGui(model_full_path);
% catch ME
%     display_msg(ME.getReport(),Constants.DEBUG,'importLusReqMenu','');
%     msg = sprintf('Failed to create Requirements for %s', gcs);
%     warndlg(msg,'CoCoSim: Warning');
% end

%end
%%
function schema = importReqMenu(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Import Requirements';
    schema.callback = @lustreReqCallback;
end


function lustreReqCallback(callbackInfo)    
    try
        importLusReqFig('gcs', gcs);
    catch ME
        display_msg(ME.getReport(),Constants.DEBUG,'importLusReqMenu','');
        msg = sprintf('Failed to import Requirements for %s', model_name);
        warndlg(msg,'CoCoSim: Warning');
    end
    
end