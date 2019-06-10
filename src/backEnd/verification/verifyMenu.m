function schema = verifyMenu(varargin)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    schema = sl_action_schema;
    schema.label = 'Prove properties';
    schema.statustip = 'Verify the current model with CoCoSim';
    schema.autoDisableWhen = 'Busy';
    schema.callback = @verifCallback;
end

function verifCallback(varargin)
    try
        clear;
        model_full_path = MenuUtils.get_file_name(gcs);
        [ CoCoSimPreferences ] = cocosim_menu.CoCoSimPreferences.load();
        warning('off')
        MenuUtils.add_pp_warning(model_full_path);
        if strcmp(CoCoSimPreferences.lustreCompiler, 'NASA')
            toLustreVerify(model_full_path, [], CoCoSimPreferences.lustreBackend);
            
        else
            if LusBackendType.isKIND2(CoCoSimPreferences.lustreBackend)
                assignin('base', 'SOLVER', 'K');
            elseif LusBackendType.isJKIND(CoCoSimPreferences.lustreBackend)
                assignin('base', 'SOLVER', 'J');
            elseif LusBackendType.isZUSTRE(CoCoSimPreferences.lustreBackend)
                assignin('base', 'SOLVER', 'Z');
            end
            VerificationMenu.runCoCoSim;
        end
        warning('on')
    catch me
        MenuUtils.handleExceptionMessage(me, 'Prove properties');
    end
end
