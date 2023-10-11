function schema = importMenu(varargin)
    schema = sl_container_schema;
    schema.label = 'Import';
    schema.statustip = 'Import Requirements or Test Obligations';
    schema.autoDisableWhen = 'Busy';

    schema.childrenFcns = {@importRequirements,@importTestObligations};
end

%%
function schema = importRequirements(varargin)
    schema = sl_action_schema;
    schema.label = 'Requirements';
    schema.callback = @importRequirementsCallback;
end

function importRequirementsCallback(varargin)
    try
        %importLustreRequirements.importLusReqFig('gcs',gcs);
        importLusReqFig_App('gcs',gcs);
    catch ME
        display_msg(ME.getReport(),Constants.DEBUG,'importMenu','');
        msg = sprintf('Failed to import Requirements for %s', model_name);
        warndlg(msg,'CoCoSim: Warning');
    end
end

function schema = importTestObligations(varargin)
    schema = sl_action_schema;
    schema.label = 'Test Obligations';
    schema.callback = @importTestObligationsCallback;
end

function importTestObligationsCallback(varargin)
    try
        %importLustreRequirements.importLusReqFig('gcs',gcs);
        %importLusTestOblFig();
        importLusReqFig_App('gcs',gcs);
    catch ME
        display_msg(ME.getReport(),Constants.DEBUG,'importMenu','');
        msg = sprintf('Failed to import Test Obligations for %s', model_name);
        warndlg(msg,'CoCoSim: Warning');
    end
end