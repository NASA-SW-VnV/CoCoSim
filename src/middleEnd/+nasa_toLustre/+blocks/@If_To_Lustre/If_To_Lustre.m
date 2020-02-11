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
classdef If_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % IF block generates boolean conditions that will be used with the
    % Action subsystems that are linked to.

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            
            [inputs, inports_dt] = nasa_toLustre.blocks.If_To_Lustre.getInputs(parent, blk);
            % get all expressions
            IfExp = nasa_toLustre.blocks.If_To_Lustre.getIfExp(blk);
            %% Step 4: start filling the definition of each output
            code = nasa_toLustre.blocks.If_To_Lustre.ifElseCode(obj, parent, blk, outputs, ...
                inputs, inports_dt, IfExp);
            obj.addCode(code);
            
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            % add your unsuported options list here
            [inputs, inports_dt] = nasa_toLustre.blocks.If_To_Lustre.getInputs(parent, blk);
            data_map = nasa_toLustre.blocks.Fcn_To_Lustre.createDataMap(inputs, inports_dt);
            IfExp = nasa_toLustre.blocks.If_To_Lustre.getIfExp(blk);
            nbOutputs=numel(blk.CompiledPortWidths.Outport);
            for j=1:nbOutputs
                [~, status] = nasa_toLustre.blocks.If_To_Lustre.formatConditionToLustre(obj, ...
                    IfExp{j}, inputs, data_map, parent, blk);
                if status
                    obj.addUnsupported_options(sprintf('ParseError  character unsupported  %s in block %s', ...
                        IfExp{j}, HtmlItem.addOpenCmd(blk.Origin_path)));
                end
            end
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        [inputs, inports_dt] = getInputs(parent, blk)

        IfExp = getIfExp(blk)

        code = ifElseCode(obj, parent, blk, outputs, inputs, inports_dt, IfExp)
        
        exp  = outputsValues(outputsNumber, outputIdx)
                
        %% new version of parsing Lustre expression.
        [exp, status] = formatConditionToLustre(obj, cond, inputs_cell, data_map, parent, blk)

    end
    
end

