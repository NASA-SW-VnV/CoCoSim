%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% node inputs outputs
function [node_struct,...
        status] = extract_node_struct(lus_file_path,...
        node_name,...
        LUSTREC,...
        LUCTREC_INCLUDE_DIR)
    if nargin < 3
        tools_config;
        status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
        if status
            err = sprintf('Binary "%s" and directory "%s" not found ',LUSTREC, LUCTREC_INCLUDE_DIR);
            display_msg(err, MsgType.ERROR, 'generate_lusi', '');
            return;
        end
    end
    try
        [node_struct, status] = ...
            LustrecUtils.extract_node_struct_using_emf(...
            lus_file_path, node_name, LUSTREC, LUCTREC_INCLUDE_DIR);
    catch
        status = 1;
    end
    if status==0
        return;
    end

    try
        [node_struct, status] = ...
            LustrecUtils.extract_node_struct_using_lusi(...
            lus_file_path, node_name, LUSTREC);
    catch
        status = 1;
    end
end

