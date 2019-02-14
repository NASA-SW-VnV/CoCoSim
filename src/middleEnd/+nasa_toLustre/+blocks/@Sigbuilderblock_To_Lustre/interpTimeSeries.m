function [codeAst, vars] = interpTimeSeries(output,time_array, ...
        data_array, blkParams,signal_index,interpolate,curTime,lus_backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    % This function write code to interpolate a piecewise linear
    % time data series.  Time and data must be 1xm array where m is
    % number of data points in the time series.


    astTime = cell(1,numel(time_array));
    astData = cell(1,numel(time_array));
    codeAst = cell(1,2*numel(time_array)+1);
    vars = cell(1,2*numel(time_array));
    for i=1:numel(time_array)
        astTime{i} = ...
            VarIdExpr(sprintf('%s_time_%d_%d',blkParams.blk_name,signal_index,i));
        astData{i} = ...
            VarIdExpr(sprintf('%s_data_%d_%d',blkParams.blk_name,signal_index,i));
        codeAst{(i-1)*2+1} = LustreEq(astTime{i}, RealExpr(time_array(i)));
        codeAst{(i-1)*2+2} = LustreEq(astData{i}, RealExpr(data_array(i)));
        vars{(i-1)*2+1} = LustreVar(astTime{i},'real');
        vars{(i-1)*2+2} = LustreVar(astData{i},'real');
    end
    conds = {};
    thens = {};

    for i=1:numel(time_array)-1
        if time_array(i) == time_array(i+1)
            continue;
        else
            epsilon = eps(time_array(i+1));
            lowerCond = BinaryExpr(BinaryExpr.GTE, ...
                curTime, ...
                astTime{i}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
            upperCond = BinaryExpr(BinaryExpr.LT, ...
                curTime, ...
                astTime{i+1}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);

            conds{end+1} = BinaryExpr(BinaryExpr.AND, lowerCond, upperCond);
            if interpolate
                thens{end+1} = ...
                    Lookup_nD_To_Lustre.interp2points_2D(astTime{i}, ...
                    astData{i}, ...
                    astTime{i+1}, ...
                    astData{i+1}, ...
                    curTime);
            else
                thens{end+1} = astData{i};
            end
        end
    end

    if numel(thens) <= 2
        value = IteExpr(conds{1},thens{1}, thens{2});
    else
        thens{end+1} = astData{numel(data_array)};
        value = IteExpr.nestedIteExpr(conds, thens);
    end
    codeAst{2*numel(time_array)+1} = LustreEq(output,value);
end
