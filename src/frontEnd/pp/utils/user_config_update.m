function  user_config_update( fcts_map, export )
    %USER_CONFIG_UPDATE Summary of this function goes here
    %   Detailed explanation goes here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
    display_msg('Saving Pre-processing configuration', MsgType.INFO, 'user_config_update', '');
    if ~exist('export','var')
        export = 0;
    end
    global ordered_pp_functions priority_pp_map;
    priority_pp_map = fcts_map;
    ordered_pp_functions = PPConfigUtils.get_ordered_functions(priority_pp_map);

    if export
        mat_path = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
            'pp_user_variables.mat');
        save(mat_path, 'ordered_pp_functions', 'priority_pp_map');
        display_msg(sprintf('Configuration exported to "%s"', mat_path), MsgType.RESULT, 'user_config_update', '');
        display_msg('The exported configuration will be loaded at every cocosim start. Unless it is removed, than default configuration will be used.', MsgType.RESULT, 'user_config_update', '');
    end
    display_msg('Configuration DONE', MsgType.RESULT, 'user_config_update', '');

    %close the browser
    com.mathworks.mlservices.MatlabDesktopServices.getDesktop.closeGroup('Web Browser');

end

