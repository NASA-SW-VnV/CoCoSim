%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% print input_values for lustre binary
function status = printLustreInputValues(...
        lustre_input_values,...
        output_dir, ...
        file_name)
    values_file = fullfile(output_dir, file_name);
    fid = fopen(values_file, 'w');
    status = 0;
    if fid == -1
        status = 1;
        err = sprintf('can not create file "%s" in directory "%s"',file_name,output_dir);
        display_msg(err, MsgType.ERROR, 'printLustreInputValues', '');
        display_msg(err, MsgType.DEBUG, 'printLustreInputValues', '');
        return;
    end
    for i=1:numel(lustre_input_values)
        value = sprintf('%.60f\n',lustre_input_values(i));
        fprintf(fid, value);
    end
    fclose(fid);
end
