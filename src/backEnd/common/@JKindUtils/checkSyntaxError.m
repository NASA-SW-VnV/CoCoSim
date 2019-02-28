%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check the lustre syntax by Jkind
function [status, output] = checkSyntaxError(lus_file_path, JLUSTRE2KIND)
    if ~exist(JLUSTRE2KIND, 'file')
        status = 1;
        output = 'jlustre2kind binary could not be found. Make Sure JKind library is installed and the path is updated in "tools_config.m"';
        return;
    end
    command = sprintf('%s -stdout "%s"',...
        JLUSTRE2KIND,  lus_file_path);
    display_msg(['JKIND_COMMAND ' command],...
        MsgType.DEBUG, 'JKindUtils.checkSyntaxError', '');
    try
        [status, output] = system(command);
    catch me
        display_msg(me.message, MsgType.DEBUG, 'JKindUtils.checkSyntaxError', '');
        status = 1;
        output = 'jlustre2kind binary could not run. Check you have Java 8 in your path';
    end
end
