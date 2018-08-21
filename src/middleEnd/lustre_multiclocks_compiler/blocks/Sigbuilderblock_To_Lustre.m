classdef Sigbuilderblock_To_Lustre < Block_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace,  ~, ~,varargin)
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
            options = obj.unsupported_options;
            
        end
        
        function [codeAst, vars] = getSigBuilderCode(obj,outputs,time,data,blk_name)
            curTime = VarIdExpr(SLX2LusUtils.timeStepStr());
            astTime = {};
            astData = {};
            codeAst = {};
            vars = {};
            for signal_index=1:numel(outputs)
                for i=1:numel(time{signal_index})
                    astTime{signal_index, i} = ...
                        VarIdExpr(sprintf('%s_time_%d_%d',blk_name,signal_index,i));
                    astData{signal_index, i} = ...
                        VarIdExpr(sprintf('%s_data_%d_%d',blk_name,signal_index,i));
                    codeAst{end+1} = LustreEq(astTime{signal_index, i}, RealExpr(time{signal_index}(i)));
                    codeAst{end+1} = LustreEq(astData{signal_index, i}, RealExpr(data{signal_index}(i)));
                    vars{end+1} = LustreVar(astTime{signal_index, i},'real');
                    vars{end+1} = LustreVar(astData{signal_index, i},'real');
                end
                conds = {};
                thens = {};
                
                for i=1:numel(time{signal_index})-1
                    if time{signal_index}(i) == time{signal_index}(i+1)
                        continue;
                    else
                        lowerCond = BinaryExpr(BinaryExpr.GTE, ...
                            curTime, ...
                            astTime{signal_index, i});
                        upperCond = BinaryExpr(BinaryExpr.LT, ...
                            curTime, ...
                            astTime{signal_index, i+1});
                        
                        conds{end+1} = BinaryExpr(BinaryExpr.AND, lowerCond, upperCond);
                        thens{end+1} = ...
                            Lookup_nD_To_Lustre.interp2points_2D(astTime{signal_index, i}, ...
                            astData{signal_index, i}, ...
                            astTime{signal_index, i+1}, ...
                            astData{signal_index, i+1}, ...
                            curTime);
                    end
                end
                
                if numel(thens) <= 2
                    value = IteExpr(conds{1},thens{1}, thens{2});
                else
                    thens{end+1} = astData{signal_index, numel(data{signal_index})};
                    value = IteExpr.nestedIteExpr(conds, thens);
                end
                codeAst{end+1} = LustreEq(outputs{signal_index},value);
            end
        end
    end
    
end

