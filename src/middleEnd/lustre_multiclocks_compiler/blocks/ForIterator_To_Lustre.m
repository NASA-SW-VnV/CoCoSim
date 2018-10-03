classdef ForIterator_To_Lustre < Block_To_Lustre
    %ForIterator_To_Lustre is partially supported by SubSystem_To_Lustre.
    %Here we add only not supported options    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            % join the lines and set the block code.
            obj.setCode( LustreEq(outputs{1}, SLX2LusUtils.iterationVariable()));
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            if isequal(blk.IterationSource, 'external')
                obj.addUnsupported_options(...
                    sprintf('Block "%s" has external iteration limit source. Only internal option is supported', ...
                    blk.Origin_path));
            end
            if isequal(blk.ExternalIncrement, 'on')
                obj.addUnsupported_options(...
                    sprintf('Block "%s" has external increment which is not supported.', ...
                    blk.Origin_path));
            end
            [~, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IterationLimit);
            if status
                obj.addUnsupported_options(...
                    sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.IterationLimit, blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
  
end

