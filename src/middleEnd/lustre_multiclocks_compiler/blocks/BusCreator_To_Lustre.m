classdef BusCreator_To_Lustre < Block_To_Lustre
    %BusCreator_To_Lustre translates the BusCreator block.
    %We inline signals, so Bus creator is just passing the input signals,
    %if there is a Bus object, it is inlined as well. The generated Lustre
    %code will be without records or Bus types.
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
            [outputs, outputs_dt] = ...
                SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            codes = cell(1, numel(outputs));
            % everything is inlined
            for i=1:numel(outputs)
                codes{i} = LustreEq(outputs{i}, inputs{i});
            end
            
            obj.setCode( MatlabUtils.strjoin(codes, ''));
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            options = obj.unsupported_options;
            if isequal(blk.OutDataTypeStr, 'Bus: <object name>')
                msg = sprintf('OutDataTypeStr "Bus: <object name>" in block %s is not supported. ',...
                    blk.Origin_path);
                obj.addUnsupported_options(msg);
            end  
            if isequal(blk.OutDataTypeStr, 'Enum: <class name>')
                msg = sprintf('OutDataTypeStr "Enum: <class name>" in block %s is not supported. ',...
                    blk.Origin_path);
                obj.addUnsupported_options(msg);
            end             
        end
    end
    
end

