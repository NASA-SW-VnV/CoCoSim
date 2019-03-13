function [call] = get_obs_callback()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    call = sprintf('paramStr = get_param(gcb, ''MaskValues'');\n');
    call = [call sprintf('if strcmp(paramStr{1}(1),''o'')\n')];
    call = [call sprintf('set_param(gcb,''MaskVisibilities'',{''on'';''on''});\n')];
    call = [call sprintf('paramStr{2} = ''ellipsoid'';\n')];
    call = [call sprintf('set_param(gcb,''MaskValues'',paramStr);\n')];
    call = [call sprintf('else\n')];
    call = [call sprintf('set_param(gcb,''MaskVisibilities'',{''on'';''off''});\n')];
    call = [call sprintf('end\n')];
    call = [call sprintf('clear paramStr;\n')];

end


