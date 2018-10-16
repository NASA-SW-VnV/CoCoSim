classdef RateTransition_To_Lustre < Block_To_Lustre
    %RateTransition_To_Lustre translates the RateTransition block.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, main_sampleTime, backend, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            %% calculated by rateTransition_ir_pp
            InportCompiledSampleTime = blk.InportCompiledSampleTime;
            OutportCompiledSampleTime = blk.OutportCompiledSampleTime;
            inTs = InportCompiledSampleTime(1);
            outTs = OutportCompiledSampleTime(1);
            inTsOffset = InportCompiledSampleTime(2);
            outTsOffset = OutportCompiledSampleTime(2);
            
            %% detect Rate type (see documentation
            if strcmp(blk.Integrity, 'on') && strcmp(blk.Deterministic, 'on')
                if inTs == outTs
                    if inTsOffset == outTsOffset
                        type = 'Copy';
                    else
                        display_msg(sprintf('RateTransition block "%s" is not supported. inTsOffset should be equal to outTsOffset.', ...
                            blk.Origin_path), MsgType.ERROR, 'RateTransition_To_Lustre','');
                        return;
                    end
                elseif inTs < outTs % fast to slow
                    if mod(int32(outTs/inTs),1)==0 &&  inTsOffset == outTsOffset && inTsOffset == 0
                        type = 'ZOH';
                    else
                        display_msg(sprintf('RateTransition block "%s" is not supported.\n The following conditionin should be met: Ts = outTs / N and inTsOffset = outTsOffset =0.', ...
                            blk.Origin_path), MsgType.ERROR, 'RateTransition_To_Lustre','');
                        return;
                    end
                else %inTs > outTs : slow to fast
                    if mod(int32(inTs/outTs),1)==0 &&  inTsOffset == outTsOffset && inTsOffset == 0
                        type = '1/z';
                    else
                        display_msg(sprintf('RateTransition block "%s" is not supported.\n The following conditionin should be met: Ts = outTs * N and inTsOffset = outTsOffset =0.', ...
                            blk.Origin_path), MsgType.ERROR, 'RateTransition_To_Lustre','');
                        return;
                    end
                end
            else
                display_msg(sprintf('RateTransition block "%s" is not supported. Data Integrity and Determinism should be checked', ...
                    blk.Origin_path), MsgType.ERROR, 'RateTransition_To_Lustre','');
                return;
            end
            
            %%
            codes = cell(1, numel(outputs));
            
            if strcmp(type, 'ZOH')
                clockName = SLX2LusUtils.clockName(outTs/main_sampleTime(1), outTsOffset/main_sampleTime(1));
                for i=1:numel(outputs)
                    %sprintf('%s = %s when %s;\n\t', outputs{i}, inputs{i}, clockName);
                    codes{i} = LustreEq(outputs{i}, ...
                        BinaryExpr(BinaryExpr.WHEN, inputs{i}, VarIdExpr(clockName)));
                end
            elseif strcmp(type, '1/z')
                clockName = SLX2LusUtils.clockName(inTs/main_sampleTime(1), inTsOffset/main_sampleTime(1));
                init_cond = SLX2LusUtils.getInitialOutput(parent, blk,...
                    blk.InitialCondition, outputDataType, numel(outputs));
                for i=1:numel(outputs)
                    %codes{i} = sprintf('%s = merge %s\n\t (true -> (%s -> pre %s))\n\t (false -> (%s -> pre %s) when false(%s));\n\t', ...
                    %    outputs{i}, clockName, init_cond{i}, inputs{i}, init_cond{i}, outputs{i}, clockName);
                    true_terms = BinaryExpr(...
                        BinaryExpr.MERGEARROW, ...
                        BooleanExpr('true'), ...
                        BinaryExpr(BinaryExpr.ARROW, ...
                                   init_cond{i}, ...
                                   UnaryExpr(UnaryExpr.PRE, inputs{i})),...
                        false);
                    if BackendType.isKIND2(backend) ...
                            || BackendType.isJKIND(backend)
                        false_clock = UnaryExpr(UnaryExpr.NOT, VarIdExpr(clockName));
                    else
                        false_clock = NodeCallExpr('false', VarIdExpr(clockName));
                    end
                    false_term = BinaryExpr(...
                        BinaryExpr.MERGEARROW, ...
                        BooleanExpr('false'), ...
                        BinaryExpr(BinaryExpr.WHEN, ...
                                   BinaryExpr(BinaryExpr.ARROW, ...
                                               init_cond{i}, ...
                                               UnaryExpr(UnaryExpr.PRE, outputs{i})),...
                                    false_clock),...
                         false);
                    codes{i} = LustreEq(outputs{i}, ...
                        MergeExpr(VarIdExpr(clockName), ...
                        {true_terms, false_term}));
                end
            elseif strcmp(type, 'Copy')
                for i=1:numel(outputs)
                    %codes{i} = sprintf('%s = %s;\n\t', outputs{i}, inputs{i});
                    codes{i} = LustreEq(outputs{i}, inputs{i});
                end
            end
            
            obj.setCode( codes );
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk, ~, backend, varargin)
            %% calculated by rateTransition_ir_pp
            InportCompiledSampleTime = blk.InportCompiledSampleTime;
            OutportCompiledSampleTime = blk.OutportCompiledSampleTime;
            inTs = InportCompiledSampleTime(1);
            outTs = OutportCompiledSampleTime(1);
            inTsOffset = InportCompiledSampleTime(2);
            outTsOffset = OutportCompiledSampleTime(2);            
            if BackendType.isKIND2(backend)
                obj.addUnsupported_options(...
                    sprintf('multi-clocks in block "%s" is currently not supported by KIND2.', blk.Origin_path));
            else
                if strcmp(blk.Integrity, 'on') && strcmp(blk.Deterministic, 'on')
                    if inTs == outTs
                        if inTsOffset ~= outTsOffset
                            obj.addUnsupported_options(sprintf('RateTransition block "%s" is not supported. inTsOffset should be equal to outTsOffset.', ...
                                blk.Origin_path));
                        end
                    elseif inTs < outTs % fast to slow
                        if ~(mod(int32(outTs/inTs),1)==0 &&  inTsOffset == outTsOffset && inTsOffset == 0)
                            obj.addUnsupported_options(sprintf('RateTransition block "%s" is not supported.\n The following conditionin should be met: Ts = outTs / N and inTsOffset = outTsOffset =0.', ...
                                blk.Origin_path));
                        end
                    else %inTs > outTs : slow to fast
                        if ~(mod(int32(inTs/outTs),1)==0 &&  inTsOffset == outTsOffset && inTsOffset == 0)
                            obj.addUnsupported_options(sprintf('RateTransition block "%s" is not supported.\n The following conditionin should be met: Ts = outTs * N and inTsOffset = outTsOffset =0.', ...
                                blk.Origin_path));
                        end
                    end
                else
                    obj.addUnsupported_options(sprintf('RateTransition block "%s" is not supported. Data Integrity and Determinism should be checked', ...
                        blk.Origin_path));
                end
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

