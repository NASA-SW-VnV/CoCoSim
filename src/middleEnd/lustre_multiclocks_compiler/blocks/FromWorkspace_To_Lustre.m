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
            
            VariableName = blk.VariableName;
            variable = evalin('base',VariableName);
            [outLusDT, ~, one] = SLX2LusUtils.get_lustre_dt(outputDataType);
            
            
            % blk parameters
%             SampleTime = blk.SampleTime;
%             Interpolate = blk.Interpolate;
%             ZeroCross = blk.ZeroCross;
%             OutputAfterFinalValue = blk.OutputAfterFinalValue;
            
            codes = {};          
            
            if isnumeric(variable)
                % for matrix
                [nrow, ncol] = size(variable);
                t = variable(:,1);
                values = variable(:,2:ncol);
                dims = ncol - 1;
            elseif isstruct(variable)
                % for struct
                t = variable.time;
                nrow = numel(t);
                values = variable.signals.values;
                dims = variable.signals.dimensions;
            else                
                display_msg(sprintf('Workspace variable must be numeric arrays or struct in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'FromWorkspace_To_Lustre', '');            
            end
            
            code = '';
            for i=1:dims
                for j=nrow:-1:1
                    a = values(j,i);
                    if j== nrow
                        code = sprintf('%f',a);
                    else
                        code = sprintf('%f -> (%s)',a,code);
                    end
                end
                codes{i} = sprintf('%s = %s; \n\t',outputs{i},code);
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};
            VariableName = blk.VariableName;
            variable = evalin('base',VariableName);
            if ~isnumeric(variable) || ~isstruct(variable)
                obj.addUnsupported_options(...
                    sprintf('Workspace variable must be numeric arrays or struct in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'FromWorkspace_To_Lustre', '');
            end
            options = obj.unsupported_options;
        end
    end
    
end

