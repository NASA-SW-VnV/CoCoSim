%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% compare Simulin outputs and Lustre outputs
function [valid, cex_msg, diff_name, diff] = ...
        compare_Simu_outputs_with_Lus_outputs(...
        input_dataSet, ...
        yout,...
        outputs_array, ...
        eps, ...
        time)
    diff_name = '';
    diff = 0;
    numberOfOutputs = length(yout.getElementNames);
    numberOfInports = length(input_dataSet.getElementNames);
    valid = true;
    cex_msg = {};
    index_out = 0;
    out_width = zeros(numberOfOutputs,1);
    for k=1:numberOfOutputs
        out_width(k) = LustrecUtils.getSignalWidth(yout{k}.Values);
    end
    for i=1:numel(time)
        cex_msg{end+1} = sprintf('*****time : %f**********\n',time(i));
        cex_msg{end+1} = sprintf('*****inputs: \n');
        for j=1:numberOfInports
            in = LustrecUtils.getSignalValuesInlinedUsingTime(input_dataSet{j}.Values, time(i));
            in_width = numel(in);
            name = input_dataSet{j}.Name;
            for jk=1:in_width
                cex_msg{end+1} = sprintf('input %s_%d: %f\n',name,jk,in(jk));
            end
        end
        cex_msg{end+1} = sprintf('*****outputs: \n');
        found_output = false;
        for k=1:numberOfOutputs
            yout_values = LustrecUtils.getSignalValuesInlinedUsingTime(yout{k}.Values, time(i));
            if isempty(yout_values)
                % signal is not defined in the current timestep
                index_out = index_out + out_width(k);
                continue;
            end
            found_output = true;
            for j=1:out_width(k)
                index_out = index_out + 1;
                output_value = ...
                    regexp(outputs_array{index_out},...
                    '\s*:\s*',...
                    'split');
                if ~isempty(output_value)
                    lus_output_name = output_value{1};
                    output_val_str = output_value{2};
                    output_val = str2num(output_val_str(2:end-1));
                    y_value = yout_values(j);

                    slx_output_name =...
                        BUtils.naming_alone(yout{k}.BlockPath.getBlock(1));
                    cex_msg{end+1} = sprintf('Simulink output %s(%d): %10.16f\n',...
                        slx_output_name, j, y_value);
                    cex_msg{end+1} = sprintf('Lustre output %s: %10.16f\n',...
                        lus_output_name,output_val);

                    if isinf(y_value) || isnan(y_value)...
                            || isinf(output_val) || isnan(output_val)
                        diff=0;
                    else
                        if y_value ~= 0
                            diff = abs(double(y_value)-output_val);
                            % percentage of difference
                            %diff = 100*abs(...
                            %   (yout_values(j)-output_val)/yout_values(j));
                        else
                            diff = abs(output_val);
                        end
                    end
                    valid = valid && (diff<eps);
                    if  ~valid
                        diff_name =  ...
                            BUtils.naming_alone(yout{k}.BlockPath.getBlock(1));
                        diff_name =  strcat(diff_name, '(',num2str(j), ')');
                        % don't break now untile this timestep finish displatyin all outputs
                        %break
                    end
                else
                    warn = sprintf('strange behavour of output %s',...
                        outputs_array{numberOfOutputs*(i-1)+k});
                    cex_msg{end+1} = warn;
                    display_msg(warn,...
                        MsgType.WARNING,...
                        'compare_Simu_outputs_with_Lus_outputs',...
                        '');
                    valid = false;
                    break;
                end
            end
            % don't break now untile this timestep finish displatyin all outputs
%             if  ~valid
%                 break;
%             end
        end
        if ~found_output
            cex_msg{end+1} = sprintf('No Output saved for this time step.\n');
        end
        if  ~valid
            break;
        end
    end
end

