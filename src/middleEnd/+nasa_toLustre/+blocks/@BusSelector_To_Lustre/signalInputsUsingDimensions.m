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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SignalsInputsMap = signalInputsUsingDimensions(...
        blk, inport_cell_dimension, inputSignalsInlined, inputs, Signals_Width_Map)
  
    
    SignalsInputsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if numel(inport_cell_dimension) ~= numel(inputSignalsInlined) ...
            && numel(inport_cell_dimension) ~= 1
        ME = MException('COCOSIM:BusSelector_To_Lustre', ...
            'Block %s is not supported. Inport and Outport Dimensions are not compatible.', HtmlItem.addOpenCmd(blk.Origin_path));
        throw(ME);
    end
    if numel(inport_cell_dimension) == 1
        % the case of Busselector with a vector input instead of
        % a bus
%         if inport_cell_dimension{1}.width ~= ...
%                 sum( cellfun(@(x) x, Signals_Width_Map.values))
%            % we can not do mapping between inputs and outpus if all
%            % of the inputs are not used.
%             ME = MException('COCOSIM:BusSelector_To_Lustre', ...
%                 'Block %s is not supported. All inputs are not selected.', HtmlItem.addOpenCmd(blk.Origin_path));
%             throw(ME);
%         end
        inputIdx = 1;
        for i=1:numel(inputSignalsInlined)
            inputSignal = inputSignalsInlined{i};
            if isKey(Signals_Width_Map, inputSignal)
                width = Signals_Width_Map(inputSignal);
                tmp_inputs =  inputs(inputIdx:inputIdx + width - 1);
                if isKey(SignalsInputsMap, inputSignal)
                    SignalsInputsMap(inputSignal) = ...
                        [SignalsInputsMap(inputSignal), ...
                        tmp_inputs];
                else
                    SignalsInputsMap(inputSignal) = ...
                        tmp_inputs;
                end
                inputIdx = inputIdx + width;
            else
                ME = MException('COCOSIM:BusSelector_To_Lustre', ...
                    'Block %s is not supported. Input Signal "%s" was not found.', HtmlItem.addOpenCmd(blk.Origin_path), inputSignal);
                throw(ME);
            end
        end

    else
        inputIdx = 1;
        for i=1:numel(inport_cell_dimension)
            width = inport_cell_dimension{i}.width;
            tmp_inputs =  inputs(inputIdx:inputIdx + width - 1);
            tokens = regexp(inputSignalsInlined{i}, '\.', 'split');
            for j=1:numel(tokens)
                prefix = coco_nasa_utils.MatlabUtils.strjoin(tokens(1:j), '.');
                if isKey(SignalsInputsMap, prefix)
                    SignalsInputsMap(prefix) = ...
                        [SignalsInputsMap(prefix), ...
                        tmp_inputs];
                else
                    SignalsInputsMap(prefix) = ...
                        tmp_inputs;
                end
            end
            inputIdx = inputIdx + width;
        end
    end
end

