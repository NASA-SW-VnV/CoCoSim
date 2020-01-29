classdef RateTransition_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %RateTransition_To_Lustre translates the RateTransition block.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
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
            
            inTsNormalized = inTs/main_sampleTime(1);
            outTsNormalized = outTs/main_sampleTime(1);
            inTsOffsetNormalized = inTsOffset/main_sampleTime(1);
            outTsOffsetNormalized = outTsOffset/main_sampleTime(1);
            % detect Rate type (see documentation)
            
            [type, error_msg] = nasa_toLustre.blocks.RateTransition_To_Lustre.getRateTransferType(blk, inTs, inTsOffset, outTs, outTsOffset );
            if ~LusBackendType.isPRELUDE(lus_backend) && ~isempty(error_msg)
                display_msg(error_msg, MsgType.ERROR, 'RateTransition_To_Lustre', '');
                return;
            end
            %
            nb_outputs = length(outputs);
            init_cond =nasa_toLustre.utils.SLX2LusUtils.getInitialOutput(parent, blk,...
                blk.InitialCondition, outputDataType, nb_outputs);
            codes = {};
            if LusBackendType.isPRELUDE(lus_backend)
                %% Using Prelude syntax
                codes = cell(1, length(outputs));
                rhs = cell(1, length(inputs));
                if outTs > inTs
                    % fast to slow /^(outTs/inTs)
                    if mod(outTs/inTs,1) < eps
                        c = nasa_toLustre.lustreAst.IntExpr(outTs / inTs);
                    else
                        c = nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, ...
                            nasa_toLustre.lustreAst.IntExpr(outTs), ...
                            nasa_toLustre.lustreAst.IntExpr(inTs));
                    end
                    for i=1:length(inputs)
                        rhs{i} = nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_DIVIDE, ...
                            inputs{i}, ...
                            c);
                    end
                elseif outTs < inTs
                    % slow to fast *^(inTs/outTs)
                    if mod(inTs / outTs,1) < eps
                        c = nasa_toLustre.lustreAst.IntExpr(inTs / outTs);
                    else
                        c = nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, ...
                            nasa_toLustre.lustreAst.IntExpr(inTs), ...
                            nasa_toLustre.lustreAst.IntExpr(outTs));
                    end
                    for i=1:length(inputs)
                        rhs{i} = nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_MULTIPLY, ...
                            nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_FBY, ...
                            init_cond{i}, inputs{i}), ...
                            c);
                    end
                else
                    for i=1:length(inputs)
                        rhs{i} = inputs{i};
                    end
                end
                % add offset
                if outTsOffset ~= 0
                    normalizedOutT = outTs / main_sampleTime(1);
                    normalizedOutP = outTsOffset / main_sampleTime(1);
                    for i=1:length(inputs)
                        rhs{i} = nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_OFFSET, ...
                            rhs{i}, ...
                            nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, ...
                            nasa_toLustre.lustreAst.IntExpr(normalizedOutP), ...
                            nasa_toLustre.lustreAst.IntExpr(normalizedOutT)));
                    end
                end
                for i=1:length(outputs)
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, rhs{i});
                end
            else
                %% Solution with clocks
                clockInName =nasa_toLustre.utils.SLX2LusUtils.clockName(inTsNormalized, inTsOffsetNormalized);
                clockInVar = nasa_toLustre.lustreAst.VarIdExpr(clockInName);
                clockOutName =nasa_toLustre.utils.SLX2LusUtils.clockName(outTsNormalized, outTsOffsetNormalized);
                clockOutVar = nasa_toLustre.lustreAst.VarIdExpr(clockOutName);
                if strcmp(type, 'Copy') && inTs == outTs && inTsOffset == outTsOffset 
                        codes = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                            inputs{i}), ...
                            (1:numel(outputs)), 'un', 0);
                    
                elseif strcmp(type, '1/z')
                    %codes{i} = sprintf('%s = merge %s\n\t (true -> (%s -> pre %s))\n\t (false -> (%s -> pre %s) when false(%s));\n\t', ...
                    %    outputs{i}, clockName, init_cond{i}, inputs{i}, init_cond{i}, outputs{i}, clockName);
                    true_terms = arrayfun(@(i) ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                        init_cond{i}, ...
                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, inputs{i})), ...
                        (1:numel(inputs)), 'un', 0);
                    addWhentrue = false;
                    
                    if nasa_toLustre.utils.SLX2LusUtils.isIgnoredSampleTime(...
                            outTsNormalized, outTsOffsetNormalized)
                        false_terms = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                            init_cond{i}, ...
                            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, outputs{i})), ...
                            (1:numel(inputs)), 'un', 0);
                        addWhenfalse = true;
                        codes = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                            nasa_toLustre.lustreAst.MergeBoolExpr(clockInVar,...
                            true_terms{i}, addWhentrue, false_terms{i}, addWhenfalse)), ...
                            (1:numel(inputs)), 'un', 0);
                    else
                        localVars = cellfun(@(x) ...
                            nasa_toLustre.lustreAst.LustreVar(strcat(x.getId(), '_local'), x.getDT()), ...
                            outputs_dt, 'un', 0);
                        obj.addVariable(localVars);
                        false_terms = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                            init_cond{i}, ...
                            nasa_toLustre.lustreAst.UnaryExpr(...
                            nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                            nasa_toLustre.lustreAst.VarIdExpr(localVars{i}.getId()))), ...
                            (1:numel(localVars)), 'un', 0);
                        addWhenfalse = true;
                        codes1 = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.LustreEq(...
                            nasa_toLustre.lustreAst.VarIdExpr(localVars{i}.getId()), ...
                            nasa_toLustre.lustreAst.MergeBoolExpr(clockInVar,...
                            true_terms{i}, addWhentrue, false_terms{i}, addWhenfalse)), ...
                            (1:numel(inputs)), 'un', 0);
                        codes2 = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                            nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.WHEN, ...
                            nasa_toLustre.lustreAst.VarIdExpr(localVars{i}.getId()),...
                            clockOutVar)), ...
                            (1:numel(outputs)), 'un', 0);
                        codes = MatlabUtils.concat(codes1, codes2);
                    end
                    
                else
%                     elseif strcmp(type, 'ZOH')
%                     % use when: out = in when c;
%                     codes = arrayfun(@(i) ...
%                         nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
%                         nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.WHEN, inputs{i}, clockOutVar)), ...
%                         (1:numel(outputs)), 'un', 0);
                    
                    % We include ZOH here: in case of input is not clocked
                    % in base clock, we transform it first to base clock
                    % then clock it to the output clock
                    
                    % Case of Copy and inTs ~= outTs or Buf or Db-buf
                    if nasa_toLustre.utils.SLX2LusUtils.isIgnoredSampleTime(...
                            inTsNormalized, inTsOffsetNormalized)
                        localVars = inputs;
                        codes1 = {};
                    else
                        true_terms = inputs;
                        addWhentrue = false;
                        localVars = cellfun(@(x) ...
                            nasa_toLustre.lustreAst.LustreVar(strcat(x.getId(), '_local'), x.getDT()), ...
                            outputs_dt, 'un', 0);
                        obj.addVariable(localVars);
                        false_terms = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                            init_cond{i}, ...
                            nasa_toLustre.lustreAst.UnaryExpr(...
                            nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                            nasa_toLustre.lustreAst.VarIdExpr(localVars{i}.getId()))), ...
                            (1:numel(localVars)), 'un', 0);
                        addWhenfalse = true;
                        codes1 = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.LustreEq(...
                            nasa_toLustre.lustreAst.VarIdExpr(localVars{i}.getId()), ...
                            nasa_toLustre.lustreAst.MergeBoolExpr(clockInVar,...
                            true_terms{i}, addWhentrue, false_terms{i}, addWhenfalse)), ...
                            (1:numel(inputs)), 'un', 0);
                    end
                    if nasa_toLustre.utils.SLX2LusUtils.isIgnoredSampleTime(...
                            outTsNormalized, outTsOffsetNormalized)
                        codes2 = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                            nasa_toLustre.lustreAst.VarIdExpr(localVars{i}.getId())), ...
                            (1:numel(outputs)), 'un', 0);
                    else
                        codes2 = arrayfun(@(i) ...
                            nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                            nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.WHEN, ...
                            nasa_toLustre.lustreAst.VarIdExpr(localVars{i}.getId()),...
                            clockOutVar)), ...
                            (1:numel(outputs)), 'un', 0);
                    end
                    codes = MatlabUtils.concat(codes1, codes2);
                end
            end
            obj.addCode( codes );
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk, lus_backend, ...
                ~, main_sampleTime, varargin)
            %% calculated by rateTransition_ir_pp
            InportCompiledSampleTime = blk.InportCompiledSampleTime;
            OutportCompiledSampleTime = blk.OutportCompiledSampleTime;
            inTs = InportCompiledSampleTime(1);
            outTs = OutportCompiledSampleTime(1);
            inTsOffset = InportCompiledSampleTime(2);
            outTsOffset = OutportCompiledSampleTime(2);
            [~, error_msg] = nasa_toLustre.blocks.RateTransition_To_Lustre.getRateTransferType(blk, inTs, inTsOffset, outTs, outTsOffset );
            if ~isempty(error_msg)
                obj.addUnsupported_options(error_msg);
            end
            outTsNormalized = outTs/main_sampleTime(1);
            outTsOffsetNormalized = outTsOffset/main_sampleTime(1);
            if ~(nasa_toLustre.utils.SLX2LusUtils.isIgnoredSampleTime(...
                    outTsNormalized, outTsOffsetNormalized)) ...
                    && ...
                    (LusBackendType.isJKIND(lus_backend)...
                    || LusBackendType.isKIND2(lus_backend))
                % y = x when C; is not supported by Kind2. It forces "when"
                % to be used in merge
                obj.addUnsupported_options(...
                    sprintf('Multi-periodic models and RateTransition block "%s" are not supported by Kind2 and JKind.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = {};%obj.unsupported_options;
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
            if strcmp(blk.Integrity, 'on')
                if strcmp(blk.Deterministic, 'on')
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
                        if mod(inTs/outTs,1) < eps &&  inTsOffset == 0 && inTsOffset == 0
                            type = '1/z';
                        else
                            error_msg = sprintf('RateTransition block "%s" is not supported.\n The following conditionin should be met: Ts = outTs * N and inTsOffset = outTsOffset =0.', ...
                                HtmlItem.addOpenCmd(blk.Origin_path));
                        end
                    end
                else
                    if inTs == outTs 
                        if inTsOffset == outTsOffset
                            type = 'Copy';
                        elseif inTsOffset < outTsOffset
                            type = 'Buf';
                        else
                            type = 'Db_buf';
                        end
                    elseif inTs < outTs 
                        if mod(inTs/outTs,1) < eps && inTsOffset <= outTsOffset
                            type = 'Buf';
                        else
                            type = 'Db_buf';
                        end
                    else
                        type = 'Db_buf';
                    end
                end
            else
                type = 'Copy';
            end
        end
    end
end

