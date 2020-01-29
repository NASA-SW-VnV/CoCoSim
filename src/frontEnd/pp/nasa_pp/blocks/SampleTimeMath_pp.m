%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [status, errors_msg] = SampleTimeMath_pp(model)
% SampleTimeMath_PROCESS Searches for SampleTimeMath blocks and replaces them by a
%  equivalent subsystem.
%   model is a string containing the name of the model to search in
status = 0;
errors_msg = {};

SampleTimeMath_list = find_system(model,...
    'LookUnderMasks', 'all', 'BlockType','SampleTimeMath');
if not(isempty(SampleTimeMath_list))
    display_msg('Processing SampleTimeMath blocks...', MsgType.INFO, 'SampleTimeMath_process', '');
    for i=1:length(SampleTimeMath_list)
        display_msg(SampleTimeMath_list{i}, MsgType.INFO, 'SampleTimeMath_process', '');
        try
            
            TsampMathOp = get_param(SampleTimeMath_list{i},'TsampMathOp' );
            weightValue = get_param(SampleTimeMath_list{i},'weightValue' );
            SaturateOnIntegerOverflow = get_param(SampleTimeMath_list{i},'SaturateOnIntegerOverflow');
            try
                dt = SLXUtils.getCompiledParam(SampleTimeMath_list{i}, 'CompiledPortDataTypes');
                inDataType = dt.Inport{1};
                OutDataTypeStr = dt.Outport{1};
            catch
                inDataType = 'Inherit: auto';
                OutDataTypeStr = get_param(SampleTimeMath_list{i}, 'OutDataTypeStr');
            end
            try
                model_sample = SLXUtils.getModelCompiledSampleTime(model);
                if   model_sample==0 || isnan(model_sample) || model_sample==Inf
                    model_sample = 0.2;
                end
            catch
                model_sample = 0.2;
            end
            suffix = TsampMathOp;
            finalBlockName = 'Product';
            if strcmp(TsampMathOp, '+')
                suffix = 'Plus';
                finalBlockName = 'Add';
            elseif strcmp(TsampMathOp, '-')
                suffix = 'Minus';
                finalBlockName = 'Add';
            elseif strcmp(TsampMathOp, '*')
                suffix = 'Multiply';
                finalBlockName = 'Product';
            elseif strcmp(TsampMathOp, '/')
                suffix = 'Divide';
                finalBlockName = 'Divide1';
            elseif strcmp(TsampMathOp, '1/Ts Only')
                suffix = 'Ts inverse';
                finalBlockName = 'Divide1';
            end
            pp_block_name = fullfile('pp_lib', strcat('SampleTimeMath', suffix));
            
            NASAPPUtils.replace_one_block(SampleTimeMath_list{i},pp_block_name);
            %set Value
            set_param(strcat(SampleTimeMath_list{i},'/weightValue'),'Value', weightValue);
            set_param(strcat(SampleTimeMath_list{i},'/Ts'),'Value', num2str(model_sample));
            %set OutDataTypeStr
            set_param(strcat(SampleTimeMath_list{i},'/weightValue'),'OutDataTypeStr', 'double');
            set_param(strcat(SampleTimeMath_list{i},'/Ts'),'OutDataTypeStr', 'double'); % back propagation causes issues if datatype of input is inherit.
            set_param(strcat(SampleTimeMath_list{i},'/u'),'OutDataTypeStr', inDataType);
            set_param(strcat(SampleTimeMath_list{i},'/', finalBlockName),'OutDataTypeStr', OutDataTypeStr);
            
            %set SaturateOnIntegerOverflow
            set_param(strcat(SampleTimeMath_list{i},'/', finalBlockName),'SaturateOnIntegerOverflow', SaturateOnIntegerOverflow);
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('SampleTimeMath pre-process has failed for block %s', SampleTimeMath_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'SampleTimeMath_process', '');
end
end

