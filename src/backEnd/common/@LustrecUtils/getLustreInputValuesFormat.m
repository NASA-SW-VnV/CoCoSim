%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% transform input struct to lustre format (inlining values)
function [lustre_input_values, status] = getLustreInputValuesFormat(...
        input_dataSet, ...
        time)
    nb_steps = numel(time);
    number_of_inputs = LustrecUtils.getNumberOfInputs(input_dataSet, nb_steps);
    status = 0;
    % Translate input_stract to lustre format (inline the inputs)
    if number_of_inputs>=1
        lustre_input_values = ones(number_of_inputs,1);
        index = 0;
        for i=1:nb_steps
            for j=1:numel(input_dataSet.getElementNames)
                %[signal_values, width] = LustrecUtils.inline_array(input_dataSet.signals(j), i-1);
                signal_values = LustrecUtils.getSignalValuesUsingTime(input_dataSet{j}.Values, time(i));
                width = numel(signal_values);
                index2 = index + width;
                lustre_input_values(index+1:index2) = signal_values;
                index = index2;
            end
        end

    else
        lustre_input_values = ones(1*nb_steps,1);
    end
end
