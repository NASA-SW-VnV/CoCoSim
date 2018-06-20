classdef Signum_To_Lustre < Block_To_Lustre
    %Signum_To_Lustre
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
            inputs = {};
%             outputDataType = blk.CompiledPortDataTypes.Outport{1};
%             [LusOutputDT,     ~] = SLX2LusUtils.get_lustre_dt(outputDataType);
            [lusInport_dt, zero] = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(1));
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            
            
            
            codes = {};
            if strcmp(lusInport_dt, 'bool')
                for j=1:numel(inputs{1})
                    codes{j} = sprintf('%s = if %s then 1 else 0;\n\t', outputs{j}, inputs{1}{j});
                end
            else
                if strcmp(lusInport_dt, 'int')
                    postfix = '';
                else
                    postfix = '.0';
                end
                for j=1:numel(inputs{1})
                    code = sprintf('if %s > %s then 1%s else if %s < %s then -1%s else 0%s', ...
                        inputs{1}{j}, zero, postfix, inputs{1}{j}, zero, postfix, postfix);
                    codes{j} = sprintf('%s = %s;\n\t', outputs{j}, code);
                end
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            options = obj.unsupported_options;
        end
    end
    
end

