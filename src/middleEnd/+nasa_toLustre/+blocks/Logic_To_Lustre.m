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
classdef Logic_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Logic_To_Lustre
    % supporting: AND, OR, NAND, NOR, XOR, NXOR, NOT
    

    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            out_lus_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            if ~strcmp(out_lus_dt, 'bool')
                [external_lib, out_conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('bool', outputDataType);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_lib);
                end
            else
                out_conv_format = {};
            end
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                lus_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(lus_dt, 'bool')
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'bool');
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                rhs = {};
                if nbInputs==1
                    scalars = cell(1, numel(inputs{1}));
                    for j=1:numel(inputs{1})
                        scalars{j} = inputs{1}{j};
                    end
                else
                    scalars = cell(1, nbInputs);
                    for j=1:nbInputs
                        scalars{j} = inputs{j}{i};
                    end
                end
                if strcmp(blk.Operator, 'AND')
                    rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, scalars);
                elseif strcmp(blk.Operator, 'OR')
                    rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.OR, scalars);
                elseif strcmp(blk.Operator, 'XOR')
                    rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.XOR, scalars);
                elseif strcmp(blk.Operator, 'NOT')
                    rhs = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, inputs{1}{i});
                elseif strcmp(blk.Operator, 'NAND')
                    rhs = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
                        nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, scalars));
                elseif strcmp(blk.Operator, 'NOR')
                    rhs = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
                        nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.OR, scalars));
                elseif strcmp(blk.Operator, 'NXOR')
                    rhs = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
                        nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.XOR, scalars));
                end
                if ~isempty(out_conv_format)
                    rhs =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(out_conv_format,rhs);
                end
                codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, rhs);
            end
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

