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
classdef HitCross_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %HitCross_To_Lustre translates the Hit Crossing block.

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            if strcmp(blk.ShowOutputPort, 'off')
                return;
            end
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            out_lus_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            obj.addVariable(outputs_dt);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            
            [HitCrossingOffset, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent,...
                blk, blk.HitCrossingOffset);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.HitCrossingOffset, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustre', '');
                return;
            end
            HitCrossingDirection = blk.HitCrossingDirection;
            slx_inport_dt = blk.CompiledPortDataTypes.Inport(1);
            [lus_inport_dt] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_inport_dt);
            offset = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(HitCrossingOffset, ...
                lus_inport_dt, slx_inport_dt);
            
            
            % create variable for crossing detection
            % out_CrossCond = (either|rising|falling)(in);
            crossingCond = arrayfun(@(i) ...
                nasa_toLustre.utils.SLX2LusUtils.getResetCode(HitCrossingDirection, lus_inport_dt, inputs{i}, offset ), ...
                (1:numel(outputs)), 'UniformOutput', 0);
            crossingCondVars = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(strcat(x.getId(), '_CrossCond')), outputs, 'un', 0);
            obj.addVariable(cellfun(@(x) ...
                nasa_toLustre.lustreAst.LustreVar(x.getId(), 'bool'), crossingCondVars, 'un', 0));
            obj.addCode(arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(crossingCondVars{i}, crossingCond{i}), ...
                (1:numel(crossingCondVars)), 'UniformOutput', 0));
            
            % create rhs as independant variable as the output may not be bool
            if strcmp(out_lus_dt, 'bool')
                rhsVars = outputs;
            else
                rhsVars = cellfun(@(x) ...
                    nasa_toLustre.lustreAst.VarIdExpr(strcat(x.getId(), '_value')), outputs, 'un', 0);
                obj.addVariable(cellfun(@(x) ...
                    nasa_toLustre.lustreAst.LustreVar(x.getId(), 'bool'), rhsVars, 'un', 0));
            end
            pre_rhsVars = cellfun(@(x) ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                nasa_toLustre.lustreAst.BoolExpr(false), ...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, x)), rhsVars, 'un', 0);
            rhsValues = arrayfun(@(i) ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.OR, ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, inputs{i}, offset), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, pre_rhsVars{i}), ...
                crossingCondVars{i})), ...
                (1:numel(rhsVars)), 'UniformOutput', 0);
            obj.addCode(arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(rhsVars{i}, rhsValues{i}), ...
                (1:numel(rhsVars)), 'UniformOutput', 0));
            
            % convert bool to output data type
            if ~strcmp(out_lus_dt, 'bool')
                [external_lib, conv_format] = ...
                    nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('bool', outputDataType);
                if ~isempty(conv_format)
                    rhs = rhsVars;
                    obj.addExternal_libraries(external_lib);
                    rhs = cellfun(@(x) ...
                        nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                        rhs, 'un', 0);
                    codes = arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(outputs{i}, rhs{i}), ...
                        (1:numel(outputs)), 'UniformOutput', 0);
                    obj.addCode( codes );
                end
            end
            
        end
        %%
        function options = getUnsupportedOptions(varargin)
            options = {};
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

