%% Check the lustre syntax
function [status, output] = checkSyntaxError(lus_file_path, KIND2, Z3)
    command = sprintf('%s --z3_bin "%s" -xml  "%s"  --enable interpreter --timeout 60 ',...
        KIND2, Z3,  lus_file_path);
    display_msg(['KIND2_COMMAND ' command],...
        MsgType.DEBUG, 'Kind2Utils2.checkSyntaxError', '');
    [status, output] = system(command);
end
