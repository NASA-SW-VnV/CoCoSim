function [time_array, data_array] = handleOutputAfterFinalValue(...
        time_array, data_array, SampleTime, option)
    % handling blk.OutputAfterFinalValue
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    t_final = time_array(end)*1.e3;
    if strcmp(option, 'Extrapolation')
        x = [time_array(end-1), time_array(end)];
        y = [data_array(end-1), data_array(end)];
        df = interp1(x, y, t_final,'linear','extrap');
        time_array = [time_array, t_final];
        data_array = [data_array, df];
    elseif strcmp(option, 'Setting to zero')
        t_next = time_array(end)+0.5*SampleTime;
        time_array = [time_array, t_next];
        data_array = [data_array, 0.0];
        time_array = [time_array, t_final];
        data_array = [data_array, 0.0];
    elseif strcmp(option, 'Holding final value')
        time_array = [time_array, t_final];
        data_array = [data_array, data_array(end)];
    else   % Cyclic repetition not supported
        display_msg(sprintf('Option %s is not supported in block %s',...
            option, HtmlItem.addOpenCmd(blk.Origin_path)), ...
            MsgType.ERROR, 'FromWorkspace_To_Lustre', '');
        return;
    end
end
