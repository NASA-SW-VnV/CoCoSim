classdef Concatenate_To_Lustre < Block_To_Lustre
    % Concatenate_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = ...
                SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs,widths] = ...
                Concatenate_To_Lustre.getBlockInputsNames_convInType2AccType(obj, parent, blk);
            [blkParams,in_matrix_dimension] = Concatenate_To_Lustre.readBlkParams(blk);
            nb_inputs = numel(widths);
            if blkParams.isVector
                [codes] = Concatenate_To_Lustre.concatenateVector(nb_inputs, inputs, outputs);
            else
                [ConcatenateDimension, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.ConcatenateDimension);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        blk.ConcatenateDimension, blk.Origin_path), ...
                        MsgType.ERROR, 'Concatenate_To_Lustre', '');
                    return;
                end
                if numel(in_matrix_dimension) > 7
                    display_msg(sprintf('More than 7 dimensions is not supported in block %s ',...
                        blk.Origin_path), ...
                        MsgType.ERROR, 'Concatenate_To_Lustre', '');
                    return;
                end                
                if ConcatenateDimension == 2    %concat matrix in row direction
                    [codes] = Concatenate_To_Lustre.concatenateDimension2(inputs, outputs,in_matrix_dimension);
                elseif ConcatenateDimension == 1    %concat matrix in column direction
                    [codes] = Concatenate_To_Lustre.concatenateDimension1(inputs, outputs,in_matrix_dimension);                    
                else
                    display_msg(sprintf('ConcatenateDimension > 2 in block %s',...
                        blk.Origin_path), ...
                        MsgType.ERROR, 'Constant_To_Lustr', '');
                    return;
                end
            end
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
         function options = getUnsupportedOptions(obj, ~, blk, varargin)
            obj.unsupported_options = {};
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
            if numel(in_matrix_dimension) > 7
                obj.addUnsupported_options(...
                    sprintf('More than 7 dimensions is not supported in block %s',...
                    blk.Origin_path), ...
                    MsgType.ERROR, 'Concatenate_To_Lustre', '');
            end
            options = obj.unsupported_options;
        end
    end
    
    methods(Static)
        
        function [blkParams,in_matrix_dimension] = readBlkParams(blk)
            blkParams = struct;
            blkParams.isVector = strcmp(blk.Mode,'Vector');
            in_matrix_dimension = ...
                Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
            % Users may specified Multidimensional array but define vector
            % for inputs.  This case is equivalent to Vector.
            if ~blkParams.isVector
                if in_matrix_dimension{1}.numDs == 1
                    blkParams.isVector = 1;
                end
            end   
        end
        
        function [codes] = concatenateDimension1(inputs, outputs,in_matrix_dimension)
            
            sizeD1 = 0;
            for i=1:numel(in_matrix_dimension)
                sizeD1 = sizeD1 + in_matrix_dimension{i}.dims(1);
            end
            outMatSize = in_matrix_dimension{1}.dims;
            outMatSize(1) = sizeD1;
            cumuRow = zeros(1,7);  % seven Ds
            cumu = 0;
            for i=1:numel(in_matrix_dimension)
                cumuRow(i) = cumu + in_matrix_dimension{i}.dims(1);
                cumu = cumu + in_matrix_dimension{i}.dims(1);
            end
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                [d1, d2,~,~,~,~,~ ] = ind2sub(outMatSize,i);   % 7 dims max
                rowCounted = 0;
                inputPortIndex = 0;
                for j=1:7
                    if d1 <= cumuRow(j)
                        inputPortIndex = j;
                        if j~= 1
                            rowCounted = cumuRow(j-1);
                        end
                        break;
                    end
                end
                curD1 = d1-rowCounted;
                curMatSize = in_matrix_dimension{inputPortIndex}.dims;
                inputIndex = sub2ind(curMatSize,curD1,d2);
                codes{i} = LustreEq(outputs{i},...
                    inputs{inputPortIndex}{inputIndex});
            end
        end
        
        function [inputs,widths] = getBlockInputsNames_convInType2AccType(obj, parent, blk)
            
            widths = blk.CompiledPortWidths.Inport;
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType)
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end            
        end        
        
        function [codes] = concatenateDimension2(inputs, outputs,in_matrix_dimension)
            codes = cell(1, numel(outputs));
            index = 0;
            for i=1:numel(in_matrix_dimension)       %loop over number of inports
                for j=1:numel(inputs{i})     % loop over each element of inport
                    index = index + 1;
                    codes{index} = LustreEq(outputs{index}, inputs{i}{j});
                end
            end
        end
        
        function [codes] = concatenateVector(nb_inputs, inputs, outputs)
            codes = cell(1, numel(outputs));
            outputIndex = 0;
            for i=1:nb_inputs
                for j=1:numel(inputs{i})
                    outputIndex = outputIndex + 1;
                    codes{outputIndex} = LustreEq(outputs{outputIndex}, inputs{i}{j});
                end
            end
        end
        
       
    end
    
end

