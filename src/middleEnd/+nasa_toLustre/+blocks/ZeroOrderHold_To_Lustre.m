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
classdef ZeroOrderHold_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %ZeroOrderHold_To_Lustre translates the ZeroOrderHold block.

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            % calculated by rateTransition_ir_pp
            OutportCompiledSampleTime = blk.OutportCompiledSampleTime;
            outTs = OutportCompiledSampleTime(1);
            outTsOffset = OutportCompiledSampleTime(2);
            period = outTs/main_sampleTime(1);
            phase = outTsOffset/main_sampleTime(1);
            if nasa_toLustre.utils.SLX2LusUtils.isIgnoredSampleTime(period, phase)
                codes = arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{i}), ...
                    (1:numel(outputs)), 'UniformOutput', 0);
            else
                clockName =nasa_toLustre.utils.SLX2LusUtils.clockName(period, phase);
%                 codes = arrayfun(@(i) ...
%                     nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
%                     nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.WHEN, ...
%                     inputs{i}, ...
%                     nasa_toLustre.lustreAst.VarIdExpr(clockName))), ...
%                     (1:numel(outputs)), 'UniformOutput', 0);
                clockVar = nasa_toLustre.lustreAst.VarIdExpr(clockName);
                init_cond =nasa_toLustre.utils.SLX2LusUtils.getInitialOutput(parent, blk,...
                    '0', outputDataType, length(outputs));
                codes = cell(1, length(outputs));
                for i=1:length(outputs)
                    % Out = if C then In else (0.0 -> (pre Out));
                    lhs = nasa_toLustre.lustreAst.IteExpr(clockVar, ...
                        inputs{i}, ...
                        nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                            init_cond{i}, ...
                            nasa_toLustre.lustreAst.UnaryExpr(...
                                nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                                outputs{i})...
                            ));
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, lhs);
                end
            end
            
            obj.addCode( codes );
        end
        %%
        function options = getUnsupportedOptions(obj,~, blk, lus_backend, varargin)
            options = obj.unsupported_options;
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

