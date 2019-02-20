classdef SineandCosine_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %SineandCosine_To_Lustre supported directly through masked subsystem
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        function obj = SineandCosine_To_Lustre()
            obj.ContentNeedToBeTranslated = 1;
        end
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin)
            % No need for code for SineandCosine_To_Lustre as 
            % it is generated as masked subsystem
            
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            %% We add assumptions on the inport values interval 
            % To obtain meaningful block output, the block input values 
            % should fall within the range [0, 1). For input values that 
            % fall outside this range, the values are cast to an unsigned 
            % data type, where overflows wrap. For these out-of-range inputs,
            % the block output might not be meaningful.
            inputs =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            inportDataType = blk.CompiledPortDataTypes.Inport{1};
            lus_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inportDataType);
            
            codes = arrayfun(@(i) ...
                AssertExpr(BinaryExpr(BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.LTE, SLX2LusUtils.num2LusExp(0, lus_dt), inputs{i}), ...
                BinaryExpr(BinaryExpr.LT, inputs{i}, SLX2LusUtils.num2LusExp(1, lus_dt)))),...
                (1:numel(inputs)), 'un', 0);
            obj.addCode(codes);
            
            %% add subsystem call
            sObj = SubSystem_To_Lustre();
            sObj.write_code(parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime);
            obj.addExtenal_node(sObj.getExternalNodes());            
            obj.addCode(sObj.getCode());
            obj.addVariable(sObj.getVariables());
            obj.addExternal_libraries(sObj.getExternalLibraries());
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

