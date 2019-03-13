%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% Show CEX
function show_CEX(cex_msg, cex_file_path )
    fid = fopen(cex_file_path, 'w');
    for i=1:numel(cex_msg)
        f_msg = cex_msg{i};
        display_msg(f_msg, MsgType.RESULT, 'CEX', '');
        fprintf(fid, f_msg);
    end
    fclose(fid);
end
