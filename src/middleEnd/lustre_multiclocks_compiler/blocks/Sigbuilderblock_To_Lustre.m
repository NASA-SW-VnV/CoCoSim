classdef Sigbuilderblock_To_Lustre < Block_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [time,data,~] = signalbuilder(blk.Origin_path);
            blk_name = SLX2LusUtils.node_name_format(blk);
%             if numel(outputs) > 1
%                 codes = cell(1, numel(outputs));
%                 for i=1:numel(outputs)
%                     codeAst = getSigBuilderCode(obj, time{i}, data{i},i,blk_name);
%                     codes{i} = LustreEq(outputs{i}, codeAst);
%                 end
%                 obj.setCode( codes );
%             elseif  numel(outputs) == 1
%                 codeAst = getSigBuilderCode(obj, time, data,1,blk_name);
%                 obj.setCode(codeAst);
%             end
            [codeAst, vars] = getSigBuilderCode(obj, outputs, time, data,blk_name);
            obj.addVariable(vars);
            obj.setCode(codeAst);
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.getUnsupportedOptions();
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        %%
        function [codeAst_all, vars_all] = getSigBuilderCode(obj,outputs,time,data,blk_name)
            % time is nx1 cell if there is more than 1 signal, time is
            % array of 1xm where m is the number of time index in the time
            % series
            codeAst_all = {};
            vars_all = {};
            curTime = VarIdExpr(SLX2LusUtils.timeStepStr());
            interpolation = 1;
            for signal_index=1:numel(outputs)
                if iscell(time)
                    time_array = time{signal_index};
                    data_array = data{signal_index};
                else
                    time_array = time;
                    data_array = data;
                end
                [codeAst, vars] = ...
                    Sigbuilderblock_To_Lustre.interpTimeSeries(...
                        outputs{signal_index},time_array, data_array, ...
                        blk_name,signal_index,interpolation, curTime);
                codeAst_all = [codeAst_all codeAst];
                vars_all = [vars_all vars];
            end
        end
    end
    methods (Static)
        function [codeAst, vars] = interpTimeSeries(output,time_array, ...
                data_array, blk_name,signal_index,interpolate,curTime)
            % This function write code to interpolate a piecewise linear
            % time data series.  Time and data must be 1xm array where m is
            % number of data points in the time series.
            astTime = cell(1,numel(time_array));
            astData = cell(1,numel(time_array));
            codeAst = cell(1,2*numel(time_array)+1);
            vars = cell(1,2*numel(time_array));
            for i=1:numel(time_array)
                astTime{i} = ...
                    VarIdExpr(sprintf('%s_time_%d_%d',blk_name,signal_index,i));
                astData{i} = ...
                    VarIdExpr(sprintf('%s_data_%d_%d',blk_name,signal_index,i));
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
                    lowerCond = BinaryExpr(BinaryExpr.GTE, ...
                        curTime, ...
                        astTime{i});
                    upperCond = BinaryExpr(BinaryExpr.LT, ...
                        curTime, ...
                        astTime{i+1});
                    
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
    end
end

