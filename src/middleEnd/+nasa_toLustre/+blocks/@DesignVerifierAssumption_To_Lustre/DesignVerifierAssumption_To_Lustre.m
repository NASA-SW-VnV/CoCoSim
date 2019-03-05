classdef DesignVerifierAssumption_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %DesignVerifierAssumption_To_Lustre translates the Assumption block from SLDV.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        function obj = DesignVerifierAssumption_To_Lustre()
            obj.ContentNeedToBeTranslated = 0;
        end
        function  write_code(obj, parent, blk, xml_trace, varargin)
            %L = nasa_toLustre.ToLustreImport.L;
            %import(L{:})
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            inport_lus_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
            if isequal(blk.outEnabled, 'on')
                % Assumption block is passing the inputs in case the option
                % outEnabled is on
                [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
                obj.addVariable(outputs_dt);
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{i});
                end
                obj.setCode( codes );
            end
            if isequal(blk.enabled, 'off') ...
                    || isequal(blk.customAVTBlockType, 'Test Condition')
                % block is not activated or not Assumption
                return;
            end
            try
                code = nasa_toLustre.blocks.DesignVerifierAssumption_To_Lustre.getAssumptionExpr(...
                    blk, inputs, inport_lus_dt);
                if ~isempty(code)
                    obj.addCode(nasa_toLustre.lustreAst.AssertExpr(code));
                end
            catch me
                display_msg(me.getReport(),  MsgType.DEBUG, ...
                    'DesignVerifierAssumption_To_Lustre', '');
                display_msg(...
                    sprintf('Expression "%s" is not supported in block %s.', ...
                    blk.intervals, HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, ...
                    'DesignVerifierAssumption_To_Lustre', '');
            end
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        exp = getIntervalExpr(x, xDT, interval)
        
        code = getAssumptionExpr(blk, inputs, inport_lus_dt)

    end
    
end

