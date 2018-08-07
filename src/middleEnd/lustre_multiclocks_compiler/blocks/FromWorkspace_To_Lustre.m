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
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            model_name = strsplit(blk.Origin_path, '/');
            model_name = model_name{1};
            SampleTime = SLXUtils.getModelCompiledSampleTime(model_name);
            
            if strcmp(blk.OutputAfterFinalValue, 'Cyclic repetition')...
                    ||  strcmp(blk.OutputAfterFinalValue, 'Extrapolation')
                display_msg(sprintf('Option %s is not supported in block %s',...
                    blk.OutputAfterFinalValue, blk.Origin_path), ...
                    MsgType.ERROR, 'FromWorkspace_To_Lustre', '');
                return;
                
            end
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);

            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            

            
            VariableName = blk.VariableName;
            [variable, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, VariableName);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    VariableName, blk.Origin_path), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            [outLusDT, zero, ~] = SLX2LusUtils.get_lustre_dt(outputDataType);
            
            
            % blk parameters
            %             SampleTime = blk.SampleTime;
            %             Interpolate = blk.Interpolate;
            %             ZeroCross = blk.ZeroCross;
            %             OutputAfterFinalValue = blk.OutputAfterFinalValue;
            
            
            
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
            dt = t(2) - t(1);
            if dt ~= SampleTime
                display_msg(sprintf('SampleTime %s in block %s is different from model SampleTime.',...
                    num2str(dt), blk.Origin_path), ...
                    MsgType.ERROR, 'FromWorkspace_To_Lustre', '');
                return;
            end
            initcode = '';
            if strcmp(blk.OutputAfterFinalValue, 'Setting to zero')
                initcode = zero;
            end
            codes = cell(1, dims);
            for i=1:dims
                for j=nrow:-1:1
                    a = values(j,i);
                    if j== nrow
                        if strcmp(blk.OutputAfterFinalValue, 'Setting to zero')
                            code = FromWorkspace_To_Lustre.addValue(a, initcode, outLusDT);   
                        else
                            if strcmp(outLusDT, 'int')
                                code = IntExpr(a);
                            elseif strcmp(outLusDT, 'bool')
                                code = BooleanExpr(a);
                            else
                                code = RealExpr(a);
                            end
                        end
                    else
                        code = FromWorkspace_To_Lustre.addValue(a, code, outLusDT);                        
                    end
                end
                
                codes{i} = LustreEq(outputs{i}, code);
                %code = initcode;
            end
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            obj.unsupported_options = {};
            VariableName = blk.VariableName;
            variable = evalin('base',VariableName);
            t = [0, 0];
            if isnumeric(variable)
                t = variable(:,1);
            elseif isstruct(variable)
                t = variable.time;
            else
                obj.addUnsupported_options(...
                    sprintf('Workspace variable must be numeric arrays or struct in block %s',...
                    blk.Origin_path));
            end
            %unsupported options
            if strcmp(blk.OutputAfterFinalValue, 'Cyclic repetition')...
                    ||  strcmp(blk.OutputAfterFinalValue, 'Extrapolation')
                obj.addUnsupported_options(...
                    sprintf('Option %s is not supported in block %s',...
                    blk.OutputAfterFinalValue, blk.Origin_path));
            end
            %Sample Time of block variable is different from Model ST
            model_name = strsplit(blk.Origin_path, '/');
            model_name = model_name{1};
            SampleTime = SLXUtils.getModelCompiledSampleTime(model_name);
            dt = t(2) - t(1);
            if dt ~= SampleTime
                obj.addUnsupported_options(...
                    sprintf('SampleTime %s in block %s is different from model SampleTime.',...
                    num2str(dt), blk.Origin_path));
                return;
            end
            options = obj.unsupported_options;
        end
    end
    methods (Static)
        function code = addValue(a, code, outLusDT)
            if strcmp(outLusDT, 'int')
                v = IntExpr(int32(a));
            elseif strcmp(outLusDT, 'bool')
                v = BooleanExpr(a);
            else
                v = RealExpr(a);
            end
            code = BinaryExpr(BinaryExpr.ARROW, ...
                    v, ...
                    UnaryExpr(UnaryExpr.PRE, code));
        end
        
    end
end

