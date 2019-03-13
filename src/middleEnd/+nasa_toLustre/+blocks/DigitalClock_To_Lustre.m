classdef DigitalClock_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %DigitalClock translates the DigitalClock block to external node
    %discretizing simulation time.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            
            % normalize digitalsampleTime to number of steps
            digitalsampleTime = blk.CompiledSampleTime(1) / main_sampleTime(1);
            realTime =  nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr());
            
            
            
            
            
            % out =  if (nb_steps mod digitalsampleTime) = 0
            %           then real_time else 0.0 -> pre out;
            
            cond2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ,...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD,...
                nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()),...
                nasa_toLustre.lustreAst.IntExpr(digitalsampleTime)), ...
                nasa_toLustre.lustreAst.IntExpr(0));
            else2 = nasa_toLustre.lustreAst.IteExpr(...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ,...
                nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()),...
                nasa_toLustre.lustreAst.IntExpr(0)), ...
                nasa_toLustre.lustreAst.RealExpr('0.0'), ...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, outputs{1}));
            codes = nasa_toLustre.lustreAst.LustreEq(outputs{1}, ...
                nasa_toLustre.lustreAst.IteExpr(cond2, ...
                realTime, ...
                else2));
            
            obj.setCode( codes);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, ...
                lus_backend, varargin)
            [~, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.SampleTime);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.SampleTime, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            if LusBackendType.isJKIND(lus_backend)
                % Jkind does not support non-constant modulus: "mod" operator.
                obj.addUnsupported_options(sprintf(...
                    ['Block "%s" is not supported by JKind model checker.', ...
                'This optiont is supported by the other model checkers. ', ...
                cocosim_menu.CoCoSimPreferences.getChangeModelCheckerMsg()], ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

