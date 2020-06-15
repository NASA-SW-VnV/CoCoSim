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
classdef RelationalOperator_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %RelationalOperator_To_Lustre translates a RelationalOperator block
    %to Lustre.

    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            op = blk.Operator;
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            [lus_outputDT, zero, one] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
                outputDataType);
            lus_in1_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
                blk.CompiledPortDataTypes.Inport(1));
            lus_in2_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
                blk.CompiledPortDataTypes.Inport(2));
            thewantedDataType = 'int';
            if strcmp(lus_in1_dt, 'real') || strcmp(lus_in2_dt, 'real')
                thewantedDataType = 'real';
            elseif strcmp(lus_in1_dt, 'bool') && strcmp(lus_in2_dt, 'bool') ...
                    && (strcmp(op, '==') || strcmp(op, '~='))
                thewantedDataType = 'bool';
            end
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(i));
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, thewantedDataType)
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, thewantedDataType);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            
            if strcmp(op, '==')
                op = nasa_toLustre.lustreAst.BinaryExpr.EQ;
            elseif strcmp(op, '~=')
                op = nasa_toLustre.lustreAst.BinaryExpr.NEQ;
            elseif strcmp(op, 'isInf') || strcmp(op, 'isNaN') ...
                    ||strcmp(op, 'isFinite')
                display_msg(sprintf('Operator %s in blk %s is not supported',...
                    blk.Operator, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'RelationalOperator_To_Lustre', '');
                return;
            end
            codes = cell(1, numel(outputs));
            for j=1:numel(outputs)
                code = nasa_toLustre.lustreAst.BinaryExpr(op, inputs{1}{j}, inputs{2}{j});
                if strcmp(lus_outputDT, 'bool')
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, code);
                else
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, ...
                        nasa_toLustre.lustreAst.IteExpr(code, one, zero));
                end
            end
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk,  varargin)
            % add your unsuported options list here
            op = blk.Operator;
           if strcmp(op, 'isInf') || strcmp(op, 'isNaN') ...
                    ||strcmp(op, 'isFinite')
                obj.addUnsupported_options(...
                    sprintf('Operator %s in blk %s is not supported',...
                    blk.Operator, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

