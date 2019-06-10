classdef RandomNumber_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %RandomNumber_To_Lustre translates the RandomNumber block to a set of
    %random number generated by Matlab
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [mean, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Mean);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Mean, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustre', '');
                return;
            end
            [variance, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Variance);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Variance, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustre', '');
                return;
            end
            a = mean - 2.57*sqrt(variance);
            b = mean + 2.57*sqrt(variance);
            nbSteps = 100;
            r = a + (b-a).*randn(nbSteps,1);
            blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            obj.addExtenal_node(nasa_toLustre.blocks.RandomNumber_To_Lustre.randomNode(blk_name, r, lus_backend));
            
            codes = {};
            if LusBackendType.isKIND2(lus_backend)
                codes{1} = nasa_toLustre.lustreAst.LustreEq(outputs{1}, ...
                    nasa_toLustre.lustreAst.NodeCallExpr(blk_name, nasa_toLustre.lustreAst.BooleanExpr('true')));
            else
                clk_var = nasa_toLustre.lustreAst.VarIdExpr(sprintf('%s_clock', blk_name));
                obj.addVariable(nasa_toLustre.lustreAst.LustreVar(clk_var, 'bool clock'));
                obj.addExternal_libraries('_make_clock');
                codes{1} = nasa_toLustre.lustreAst.LustreEq(clk_var, ...
                    nasa_toLustre.lustreAst.NodeCallExpr('_make_clock',...
                    {nasa_toLustre.lustreAst.IntExpr(nbSteps), nasa_toLustre.lustreAst.IntExpr(0)}));
                % generating 100 random random that will be repeated each 100
                % steps
                codes{2} = nasa_toLustre.lustreAst.LustreEq(outputs{1}, ...
                    nasa_toLustre.lustreAst.EveryExpr(blk_name, nasa_toLustre.lustreAst.BooleanExpr('true'), clk_var));
            end
            
            obj.addCode( codes );
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, lus_backend, varargin)
            
            [~, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Mean);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Mean, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            [~, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Variance);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Variance, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            if LusBackendType.isJKIND(lus_backend)
                obj.addUnsupported_options(sprintf(...
                    ['Block "%s" is not supported by JKind model checker.', ...
                'This optiont is supported by the other model checks. ', ...
                cocosim_menu.CoCoSimPreferences.getChangeModelCheckerMsg()], ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(obj, ~, ~, lus_backend, varargin)
            is_Abstracted = LusBackendType.isKIND2(lus_backend);
        end
    end
    methods(Static)
        node = randomNode(blk_name, r, lus_backend)

    end
end

