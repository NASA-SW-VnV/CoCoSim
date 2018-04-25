function [] = SampleTimeMath_pp(model)
% SampleTimeMath_PROCESS Searches for SampleTimeMath blocks and replaces them by a
%  equivalent subsystem.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SampleTimeMath_list = find_system(model,'LookUnderMasks', 'all', 'BlockType','SampleTimeMath');
if not(isempty(SampleTimeMath_list))
    display_msg('Processing SampleTimeMath blocks...', MsgType.INFO, 'SampleTimeMath_process', '');
    for i=1:length(SampleTimeMath_list)
        display_msg(SampleTimeMath_list{i}, MsgType.INFO, 'SampleTimeMath_process', '');
        TsampMathOp = get_param(SampleTimeMath_list{i},'TsampMathOp' );
        weightValue = get_param(SampleTimeMath_list{i},'weightValue' );
        try
            model_sample = SLXUtils.get_BlockDiagram_SampleTime(model);
            if   model_sample==0 || isnan(model_sample) || model_sample==Inf
                model_sample = 0.2;
            end
        catch
            model_sample = 0.2;
        end
        suffix = TsampMathOp;
        if strcmp(TsampMathOp, '+')
            suffix = 'Plus';
        elseif strcmp(TsampMathOp, '-')
            suffix = 'Minus';
        elseif strcmp(TsampMathOp, '*')
            suffix = 'Multiply';
        elseif strcmp(TsampMathOp, '/')
            suffix = 'Divide';
        elseif strcmp(TsampMathOp, '1/Ts Only')
            suffix = 'Ts inverse';
        end
        pp_block_name = fullfile('pp_lib', strcat('SampleTimeMath', suffix));
        replace_one_block(SampleTimeMath_list{i},pp_block_name);
        set_param(strcat(SampleTimeMath_list{i},'/weightValue'),'Value', weightValue);
        set_param(strcat(SampleTimeMath_list{i},'/Ts'),'Value', num2str(model_sample));
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'SampleTimeMath_process', '');
end
end

