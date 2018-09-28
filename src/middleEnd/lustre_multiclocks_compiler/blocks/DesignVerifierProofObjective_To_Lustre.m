classdef DesignVerifierProofObjective_To_Lustre < Block_To_Lustre
    %DesignVerifierProofObjective_To_Lustre translates the Proof objective
    % block from SLDV library.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        function obj = DesignVerifierProofObjective_To_Lustre()
            obj.ContentNeedToBeTranslated = 0;
        end
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            inport_lus_dt = SLX2LusUtils.get_lustre_dt(inport_dt);
            if isequal(blk.outEnabled, 'on')
                % Assumption block is passing the inputs in case the option
                % outEnabled is on
                [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
                obj.addVariable(outputs_dt);
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    codes{i} = LustreEq(outputs{i}, inputs{i});
                end
                obj.setCode( codes );
            end
            if isequal(blk.enabled, 'off') ...
                    || isequal(blk.customAVTBlockType, 'Test Condition')
                % block is not activated or not Assumption
                return;
            end
            try
                code = DesignVerifierAssumption_To_Lustre.getAssumptionExpr(...
                    blk, inputs, inport_lus_dt);
                if ~isempty(code)
                    blk_name = SLX2LusUtils.node_name_format(blk);
                    parent_name = SLX2LusUtils.node_name_format(parent);
                    obj.addCode(LocalPropertyExpr( blk_name, code ));
                    xml_trace.add_Property(blk.Origin_path, parent_name, blk_name, 1, ...
                        'localProperty')
                end
            catch me
                display_msg(me.getReport(),  MsgType.DEBUG, ...
                    'DesignVerifierProofObjective_To_Lustre', '');
                display_msg(...
                    sprintf('Expression "%s" is not supported in block %s.', ...
                    blk.intervals, blk.Origin_path), MsgType.ERROR, ...
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
   
    
end

