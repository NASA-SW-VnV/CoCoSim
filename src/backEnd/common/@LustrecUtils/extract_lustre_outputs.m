%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% extract lustre outputs from lustre binary
function status = extract_lustre_outputs(...
        lus_file_name,...
        binary_dir, ...
        node_name,...
        input_file_name,...
        output_file_name)
    PWD = pwd;
    cd(binary_dir);
    lustre_binary = ...
        strcat(lus_file_name,...
        '_',...
        nasa_toLustre.utils.SLX2LusUtils.name_format(node_name));
    command  = sprintf('./%s  < %s > %s',...
        lustre_binary, input_file_name, output_file_name);
    display_msg(command, MsgType.DEBUG, 'extract_lustre_outputs', '');
    [status, binary_out] =system(command);
    if status
        err = sprintf('lustrec binary failed for model "%s"',...
            lus_file_name,binary_out);
        display_msg(err, MsgType.ERROR, 'extract_lustre_outputs', '');
        display_msg(err, MsgType.DEBUG, 'extract_lustre_outputs', '');
        display_msg(binary_out, MsgType.DEBUG, 'extract_lustre_outputs', '');
        cd(PWD);
        return
    else
        % remove *simu_in* files
        MatlabUtils.reg_delete(binary_dir, '*simu.in*');
        MatlabUtils.reg_delete(binary_dir, '*simu.out*');
    end
end
