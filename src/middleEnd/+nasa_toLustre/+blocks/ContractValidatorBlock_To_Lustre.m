classdef ContractValidatorBlock_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % ContractValidatorBlock_To_Lustre ignores Validator block in contract
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                ~, main_sampleTime, varargin)
            if LusBackendType.isKIND2(lus_backend)
                % Validator block willl be ignored as it will be
                % supported in its contract
                return;
            end
            % TODO: Validator = sofar(A) => G
            [outputs, outputs_dt] =...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            obj.addCode(cellfun(@(x) ...
                nasa_toLustre.lustreAst.LustreEq(x, nasa_toLustre.lustreAst.BoolExpr(true)), ...
                outputs, 'un', 0));
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % add your unsuported options list here
            %Check Validator inports should be all one
            %dimensional booleans
            for i=1:numel(blk.CompiledPortWidths.Inport)
                if blk.CompiledPortWidths.Inport(i) > 1
                    obj.addUnsupported_options(...
                        sprintf('Expected Scalar Boolean in Inport %d in Block Validator %s, got a width of %d.', ...
                        i, blk.Origin_path, blk.CompiledPortWidths.Inport(i)));
                end
            end
            options = obj.unsupported_options;
            
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

