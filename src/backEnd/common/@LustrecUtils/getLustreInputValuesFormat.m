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
%

%% transform input struct to lustre format (inlining values)
function [lustre_input_values, status] = getLustreInputValuesFormat(...
        input_dataSet, time, node_struct)
    nb_steps = length(time);
    %number_of_inputs_For_AllSimulation = LustrecUtils.getNumberOfInputsInlinedFromDataSet(input_dataSet, nb_steps);
    number_of_inputs  = LustrecUtils.getNumberOfInputsInlinedFromDataSet(input_dataSet, 1);
    status = 0;
    lustre_input_values = [];
    addTimeStep = false;
    addnbStep = false;
    if nargin >= 3
        node_inputs = node_struct.inputs;
        if (number_of_inputs == 0) && (length(node_inputs) == 1) 
            %ignore it's "_virtual" input for Lustrec
        elseif length(node_inputs) > number_of_inputs
            % lustrec node_struct replace "__" in the begining of variable name to 'xx'
            time_stepVarName  = regexprep(nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), ...
                '^__', 'xx');
            nbStepStrVarName = regexprep(nasa_toLustre.utils.SLX2LusUtils.nbStepStr(), ...
                '^__', 'xx');
            if length(node_inputs) == number_of_inputs + 2 ...
                    && strcmp(node_inputs(end-1).name, time_stepVarName)...
                    && strcmp(node_inputs(end).name, nbStepStrVarName)
                %additional time_step and nb_step inputs
                addTimeStep = true;
                addnbStep = true;
                timestep = time;
                nbstepValues = (0:nb_steps-1);
            else
                % has clock inputs. Not supported for the moment.
                display_msg('Number of inputs in Lustre node does not match the number of inputs in Simulink', ...
                    MsgType.ERROR, 'LustrecUtils.getLustreInputValuesFormat', '');
                status = 1;
                return;
            end
        end
    end
    % Translate input_stract to lustre format (inline the inputs)
    if number_of_inputs>=1
        %lustre_input_values = ones(number_of_inputs_For_AllSimulation,1);
        lustre_input_values = [];
        for i=1:nb_steps
            for j=1:numel(input_dataSet.getElementNames)
                %[signal_values, width] = LustrecUtils.inline_array(input_dataSet.signals(j), i-1);
                signal_values = LustrecUtils.getSignalValuesInlinedUsingTime(input_dataSet{j}.Values, time(i));
                width = length(signal_values);
                lustre_input_values(end+1:end+width) = signal_values;
            end
            if addTimeStep
                lustre_input_values(end+1) = timestep(i);
            end
            if addnbStep
                lustre_input_values(end+1) = nbstepValues(i);
            end
        end
        
    else
        % virtual inputs :_virtual:bool
        lustre_input_values = ones(1*nb_steps,1);
    end
end
