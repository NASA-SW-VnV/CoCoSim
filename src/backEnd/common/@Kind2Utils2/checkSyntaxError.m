%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% Check the lustre syntax
function [status, output] = checkSyntaxError(lus_file_path, KIND2, Z3)
    command = sprintf('%s --enable interpreter -xml  "%s" --timeout 60 --z3_bin %s ',...
        KIND2,  lus_file_path, Z3);
    display_msg(['KIND2_COMMAND ' command],...
        MsgType.DEBUG, 'Kind2Utils2.checkSyntaxError', '');
    [status, output] = system(command);
    if status == 20
        status = 0;
    end
end
