classdef FromWorkspace_To_Lustre < Block_To_Lustre
    %FromWorkspace_To_Lustre 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            inputs = {};
            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            % there is no inputs
%             for i=1:nbInputs
%                 inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
%                 if numel(inputs{i}) < max_width
%                     inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
%                 end
%                 inport_dt = blk.CompiledPortDataTypes.Inport(i);
%                 %converts the input data type(s) to
%                 %its accumulator data type
%                 if ~strcmp(inport_dt, outputDataType)
%                     [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
%                     if ~isempty(external_lib)
%                         obj.addExternal_libraries(external_lib);
%                         inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
%                     end
%                 end
%             end
%             VariableName = blk.VariableName
%             SampleTime  = blk.SampleTime
%             Interpolate = blk.Interpolate
%             ZeroCross = blk.ZeroCross
%             OutputAfterFinalValue = blk.OutputAfterFinalValue
            
            VariableName = blk.VariableName;
            variable = evalin('base',VariableName);
            [outLusDT, ~, one] = SLX2LusUtils.get_lustre_dt(outputDataType);
            codes = {};

            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};

           
            options = obj.unsupported_options;
        end
    end
    
end

