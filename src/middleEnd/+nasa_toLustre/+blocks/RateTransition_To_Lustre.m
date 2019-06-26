classdef RateTransition_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %RateTransition_To_Lustre translates the RateTransition block.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            % calculated by rateTransition_ir_pp
            InportCompiledSampleTime = blk.InportCompiledSampleTime;
            OutportCompiledSampleTime = blk.OutportCompiledSampleTime;
            inTs = InportCompiledSampleTime(1);
            outTs = OutportCompiledSampleTime(1);
            inTsOffset = InportCompiledSampleTime(2);
            outTsOffset = OutportCompiledSampleTime(2);
            
            % detect Rate type (see documentation
            
            [type, error_msg] = nasa_toLustre.blocks.RateTransition_To_Lustre.getRateTransferType(blk, inTs, inTsOffset, outTs, outTsOffset );
            if ~isempty(error_msg)
                display_msg(error_msg, MsgType.ERROR, 'RateTransition_To_Lustre', '');
                return;
            end
            %
            
            
            if strcmp(type, 'ZOH')
                clockName =nasa_toLustre.utils.SLX2LusUtils.clockName(outTs/main_sampleTime(1), outTsOffset/main_sampleTime(1));
                clockVar = nasa_toLustre.lustreAst.VarIdExpr(clockName);
                init_cond =nasa_toLustre.utils.SLX2LusUtils.getInitialOutput(parent, blk,...
                    blk.InitialCondition, outputDataType, numel(outputs));
                if LusBackendType.isJKIND(lus_backend)...
                        || LusBackendType.isKIND2(lus_backend)
                    %TODO: second argument of condact should be a node call
                    % use merge for Kind2 instead
                    condact_args{1} = clockVar;
                    condact_args{2} = nasa_toLustre.lustreAst.TupleExpr(inputs);
                    condact_args = [condact_args, init_cond];
                    codes{1} = nasa_toLustre.lustreAst.LustreEq(outputs,...
                        nasa_toLustre.lustreAst.CondactExpr(condact_args));
                else
                    % use when: out = in when c;
                    codes = arrayfun(@(i) ...
                        nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.WHEN, inputs{i}, clockVar)), ...
                        (1:numel(outputs)), 'un', 0);
                end
            elseif strcmp(type, '1/z')
                clockName =nasa_toLustre.utils.SLX2LusUtils.clockName(inTs/main_sampleTime(1), inTsOffset/main_sampleTime(1));
                clockVar = nasa_toLustre.lustreAst.VarIdExpr(clockName);
                init_cond =nasa_toLustre.utils.SLX2LusUtils.getInitialOutput(parent, blk,...
                    blk.InitialCondition, outputDataType, numel(outputs));
                if LusBackendType.isJKIND(lus_backend)...
                        || LusBackendType.isKIND2(lus_backend)
                    %TODO: second argument of condact should be a node call
                    % use merge for Kind2 instead
                    condact_args{1} = clockVar;
                    pre_inputs = arrayfun(@(i) ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                        init_cond{i}, ...
                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, inputs{i})), ...
                        (1:numel(inputs)), 'un', 0);
                    condact_args{2} = nasa_toLustre.lustreAst.TupleExpr(pre_inputs);
                    condact_args = [condact_args, init_cond];
                    codes{1} = nasa_toLustre.lustreAst.LustreEq(outputs,...
                        nasa_toLustre.lustreAst.CondactExpr(condact_args));
                else
                    %codes{i} = sprintf('%s = merge %s\n\t (true -> (%s -> pre %s))\n\t (false -> (%s -> pre %s) when false(%s));\n\t', ...
                    %    outputs{i}, clockName, init_cond{i}, inputs{i}, init_cond{i}, outputs{i}, clockName);
                    true_terms = arrayfun(@(i) ...
                        nasa_toLustre.lustreAst.BinaryExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr.MERGEARROW, ...
                        nasa_toLustre.lustreAst.BooleanExpr('true'), ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                        init_cond{i}, ...
                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, inputs{i})),...
                        false), ...
                        (1:numel(inputs)), 'un', 0);
                    false_clock = nasa_toLustre.lustreAst.NodeCallExpr('false', clockVar);
                    false_terms = arrayfun(@(i) ...
                        nasa_toLustre.lustreAst.BinaryExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr.MERGEARROW, ...
                        nasa_toLustre.lustreAst.BooleanExpr('false'), ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.WHEN, ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                        init_cond{i}, ...
                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, outputs{i})),...
                        false_clock),...
                        false), ...
                        (1:numel(inputs)), 'un', 0);
                    codes = arrayfun(@(i) ...
                        nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                        nasa_toLustre.lustreAst.MergeExpr(clockVar, ...
                        {true_terms{i}, false_terms{i}})), ...
                        (1:numel(inputs)), 'un', 0);
                end
            elseif strcmp(type, 'Copy')
                for i=1:numel(outputs)
                    %codes{i} = sprintf('%s = %s;\n\t', outputs{i}, inputs{i});
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{i});
                end
            end
            
            obj.addCode( codes );
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk, lus_backend, varargin)
            %% calculated by rateTransition_ir_pp
            InportCompiledSampleTime = blk.InportCompiledSampleTime;
            OutportCompiledSampleTime = blk.OutportCompiledSampleTime;
            inTs = InportCompiledSampleTime(1);
            outTs = OutportCompiledSampleTime(1);
            inTsOffset = InportCompiledSampleTime(2);
            outTsOffset = OutportCompiledSampleTime(2);
            [type, error_msg] = nasa_toLustre.blocks.RateTransition_To_Lustre.getRateTransferType(blk, inTs, inTsOffset, outTs, outTsOffset );
            if ~isempty(error_msg)
                obj.addUnsupported_options(error_msg);
            end
            if ~strcmp(type, 'Copy') && ...
                    (LusBackendType.isJKIND(lus_backend)...
                    || LusBackendType.isKIND2(lus_backend))
                obj.addUnsupported_options(...
                    sprintf('RateTransition block "%s" is not supported by Kind2 and JKind.', ...
                            HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods (Static)
        function [type, error_msg] = getRateTransferType(blk, inTs, inTsOffset, outTs, outTsOffset )
            type = '';
            error_msg = '';
            if strcmp(blk.Integrity, 'on') && strcmp(blk.Deterministic, 'on')
                if inTs == outTs
                    if inTsOffset == outTsOffset
                        type = 'Copy';
                    else
                        error_msg = sprintf('RateTransition block "%s" is not supported. inTsOffset should be equal to outTsOffset.', ...
                            HtmlItem.addOpenCmd(blk.Origin_path));
                    end
                elseif inTs < outTs % fast to slow
                    if mod(outTs/inTs,1) < eps &&  inTsOffset == outTsOffset && inTsOffset == 0
                        type = 'ZOH';
                    else
                        error_msg = sprintf('RateTransition block "%s" is not supported.\n The following conditionin should be met: Ts = outTs / N and inTsOffset = outTsOffset =0.', ...
                            HtmlItem.addOpenCmd(blk.Origin_path));
                    end
                else %inTs > outTs : slow to fast
                    if mod(inTs/outTs,1) < eps &&  inTsOffset == outTsOffset && inTsOffset == 0
                        type = '1/z';
                    else
                        error_msg = sprintf('RateTransition block "%s" is not supported.\n The following conditionin should be met: Ts = outTs * N and inTsOffset = outTsOffset =0.', ...
                            HtmlItem.addOpenCmd(blk.Origin_path));
                    end
                end
            else
                error_msg = sprintf('RateTransition block "%s" is not supported. Data Integrity and Determinism should be checked', ...
                    HtmlItem.addOpenCmd(blk.Origin_path));
            end
        end
    end
end

