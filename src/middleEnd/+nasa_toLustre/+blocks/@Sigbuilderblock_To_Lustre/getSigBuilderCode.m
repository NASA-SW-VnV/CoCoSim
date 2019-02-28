function [codeAst_all, vars_all, external_lib] = getSigBuilderCode(...
        obj,outputs,time,data,SampleTime,blkParams,lus_backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    % time is nx1 cell if there is more than 1 signal, time is
    % array of 1xm where m is the number of time index in the time
    % series
    codeAst_all = {};
    vars_all = {};
    external_lib = {'LustMathLib_abs_real'};
    curTime = nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr());
    interpolation = 1;
    for signal_index=1:numel(outputs)
        if iscell(time)
            time_array = time{signal_index};
            data_array = data{signal_index};
        else
            time_array = time;
            data_array = data;
        end

        [time_array, data_array] = ...
            nasa_toLustre.blocks.FromWorkspace_To_Lustre.handleOutputAfterFinalValue(...
            time_array, data_array, SampleTime,...
            blkParams.OutputAfterFinalValue);

        [codeAst, vars] = ...
            nasa_toLustre.blocks.Sigbuilderblock_To_Lustre.interpTimeSeries(...
            outputs{signal_index},time_array, data_array, ...
            blkParams,signal_index,interpolation, curTime,lus_backend);
        codeAst_all = [codeAst_all codeAst];
        vars_all = [vars_all vars];
    end
end
