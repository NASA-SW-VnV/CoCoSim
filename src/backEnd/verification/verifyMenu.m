function schema = verifyMenu(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
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
clear;
model_full_path = MenuUtils.get_file_name(gcs);
[ CoCoSimPreferences ] = loadCoCoSimPreferences();
warning('off')
if CoCoSimPreferences.lustreCompiler ==1
    toLustreVerify(model_full_path, [], CoCoSimPreferences.lustreBackend);
    
elseif CoCoSimPreferences.lustreCompiler
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
end


% 
% function schema = getZustre(varargin)
% schema = sl_action_schema;
% schema.label = 'Zustre';
% schema.callback = @zustreCallback;
% end
% 
% function zustreCallback(varargin)
% clear;
% assignin('base', 'SOLVER', 'Z');
% assignin('base', 'RUST_GEN', 0);
% assignin('base', 'C_GEN', 0);
% VerificationMenu.runCoCoSim;
% end
% 
% 
% function schema = getKind(varargin)
% schema = sl_action_schema;
% schema.label = 'Kind2';
% schema.callback = @kindCallback;
% end
% 
% function kindCallback(varargin)
% clear;
% model_full_path = MenuUtils.get_file_name(gcs);
% [ CoCoSimPreferences ] = loadCoCoSimPreferences();
% warning('off')
% if CoCoSimPreferences.lustreCompiler ==1
%     toLustreVerify(model_full_path);
% elseif CoCoSimPreferences.lustreCompiler
%     assignin('base', 'SOLVER', 'K');
%     VerificationMenu.runCoCoSim;
% end
% warning('on')
% end
% 
% function schema = getJKind(varargin)
% schema = sl_action_schema;
% schema.label = 'JKind';
% schema.callback = @jkindCallback;
% end
% 
% function jkindCallback(varargin)
% clear;
% assignin('base', 'SOLVER', 'J');
% assignin('base', 'RUST_GEN', 0);
% assignin('base', 'C_GEN', 0);
% VerificationMenu.runCoCoSim;
% end
% 
% function  schema = helpItem(varargin)
% schema = sl_action_schema;
% schema.label = 'Help';
% schema.callback = @helpCallback;
% end
% 
% function helpCallback(varargin)
% msg = sprintf('We recommend using Kind2 for compositional and contracts based Verification.');
% msg = sprintf('%s\nZustre may be good for non-linear functions.', msg);
% helpdlg(msg, 'CoCoSim help');
% end
