function schema = precontext_menu(varargin)
    %cocoSim_menu Define the custom menu function.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    schema = sl_container_schema;
    schema.label = 'CoCoSim';
    schema.statustip = 'Automated Analysis Framework';
    schema.autoDisableWhen = 'Busy';
    
    schema.childrenFcns = {@verificationResultPrecontextMenu, ...
        @MiscellaneousMenu.replaceInportsWithSignalBuilders};
    
end

function schema = verificationResultPrecontextMenu(varargin)
    schema = sl_container_schema;
    schema.label = 'Verification Results';
    schema.statustip = 'Get the Active verification results';
    schema.autoDisableWhen = 'Busy';
    schema.childrenFcns = {...
            @VerificationMenu.displayHtmlVerificationResults,...
            @VerificationMenu.compositionalOptions...
            };
    modelWorkspace = get_param(gcs,'modelworkspace');
    if ~isempty(modelWorkspace) && modelWorkspace.hasVariable('compositionalMap')
        schema.state = 'Enabled';        
    else
        schema.state = 'Hidden';
    end
end
