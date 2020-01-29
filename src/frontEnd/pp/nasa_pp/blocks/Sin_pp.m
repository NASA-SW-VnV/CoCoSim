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
%function [status, errors_msg] = Sin_pp(model)
    % Sin_pp Searches for Sine wave blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    % Processing Sine wave blocks
    status = 0;
    errors_msg = {};
    
    Sin_list = find_system(model, ...
        'LookUnderMasks', 'all', 'BlockType','Sin');
    if not(isempty(Sin_list))
        display_msg('Replacing Sin blocks...', MsgType.INFO,...
            'Sin_pp', '');
        for i=1:length(Sin_list)
            try
                display_msg(Sin_list{i}, MsgType.INFO, ...
                    'Sin_pp', '');
                SineType = get_param(Sin_list{i},'SineType');
                TimeSource = get_param(Sin_list{i},'TimeSource');
                Amplitude = get_param(Sin_list{i},'Amplitude');
                Bias = get_param(Sin_list{i},'Bias');
                Frequency = get_param(Sin_list{i},'Frequency');
                Phase = get_param(Sin_list{i},'Phase');
                SampleTime = get_param(Sin_list{i},'SampleTime');
                
                if strcmp(SineType, 'Sample based')
                    [Samples, ~, status] = SLXUtils.evalParam(...
                        model, ...
                        get_param(Sin_list{i}, 'Parent'), ...
                        Sin_list{i}, ...
                        get_param(Sin_list{i},'Samples'));
                    if status
                        errors_msg{end + 1} = sprintf('Sin pre-process has failed for block %s. Samples parameter could not be read.', Sin_list{i});
                        continue;
                    end
                    sampleTime = SLXUtils.getCompiledParam(Sin_list{i}, 'CompiledSampleTime');
                    Frequency = num2str(2*pi/(Samples* sampleTime(1)));
                    [Offset, ~, status] = SLXUtils.evalParam(...
                        model, ...
                        get_param(Sin_list{i}, 'Parent'), ...
                        Sin_list{i}, ...
                        get_param(Sin_list{i},'Offset'));
                    if status
                        errors_msg{end + 1} = sprintf('Sin pre-process has failed for block %s. Offset parameter could not be read.', Sin_list{i});
                        continue;
                    end
                    Phase = num2str(2*pi*Offset/Samples);
                end
                
                NASAPPUtils.replace_one_block(Sin_list{i},fullfile('pp_lib', 'SineWaveFunction'));
                
                set_param(strcat(Sin_list{i},'/Freq'),...
                    'Value',Frequency);
                set_param(strcat(Sin_list{i},'/Phase'),...
                    'Value',Phase);
                set_param(strcat(Sin_list{i},'/Amp'),...
                    'Value',Amplitude);
                set_param(strcat(Sin_list{i},'/Bias'),...
                    'Value',Bias);
                
                if strcmp(TimeSource, 'Use simulation time')
                    if str2num(SampleTime) == 0
                        NASAPPUtils.replace_one_block(strcat(Sin_list{i},'/In1'),...
                            'simulink/Sources/Clock');
                    else
                        NASAPPUtils.replace_one_block(strcat(Sin_list{i},'/In1'),...
                            'simulink/Sources/Digital Clock');
                        set_param(strcat(Sin_list{i},'/In1'),...
                            'SampleTime',SampleTime);
                    end
                end
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('Sin pre-process has failed for block %s', Sin_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'Sin_pp', '');
    end
    
end

