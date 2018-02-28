classdef Product_To_Lustre < Block_To_Lustre
    %Product_To_Lustre The Product block performs addition or subtraction on its
    %inputs. This block can add or subtract scalar, vector, or matrix inputs.
    %It can also collapse the elements of a signal.
    %The Sum block first converts the input data type(s) to
    %its accumulator data type, then performs the specified operations.
    %The block converts the result to its output data type using the
    %specified rounding and overflow modes.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
           
            OutputDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            isSumBlock = false;
            [codes, outputs_dt] = Sum_To_Lustre.getSumProductCodes(obj, parent, blk, OutputDataTypeStr,isSumBlock, OutputDataTypeStr);
       
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    
end

