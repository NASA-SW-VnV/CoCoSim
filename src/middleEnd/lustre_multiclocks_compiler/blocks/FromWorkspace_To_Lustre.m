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
        
        function  write_code(obj, parent, blk, xml_trace, ~, backend, varargin)
  
            model_name = strsplit(blk.Origin_path, '/');
            model_name = model_name{1};
            SampleTime = SLXUtils.getModelCompiledSampleTime(model_name);
            
            interpolate = 1;
            if strcmp(blk.Interpolate, 'off')
                interpolate = 0;
            end
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};                        
            VariableName = blk.VariableName;
            [variable, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, VariableName);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    VariableName, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            [outLusDT, zero, ~] = SLX2LusUtils.get_lustre_dt(outputDataType);
                                                
            if isnumeric(variable)
                % for matrix
                [nrow, ncol] = size(variable);
                t = variable(:,1);
                values = variable(:,2:ncol);
                dims = ncol - 1;
            elseif isa(variable,'timeseries')
                [n,m] = size(variable.Data);
                t = variable.Time;
                values = variable.Data;   
                dims = m;
            elseif isstruct(variable)
                % for struct
                t = variable.time;
                nrow = numel(t);
                values = variable.signals.values;
                dims = variable.signals.dimensions;
            else
                display_msg(sprintf('Workspace variable must be numeric arrays or struct in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'FromWorkspace_To_Lustre', '');
                return;
            end

            blk_name = SLX2LusUtils.node_name_format(blk);
            codeAst_all = {};
            vars_all = {};   
            simTime = VarIdExpr(SLX2LusUtils.timeStepStr());    % modify to do cyclic repetition?
            for i=1:dims  

                time_array = t';
                data_array = values(:,i)';
                
                if numel(t) == 1      % constant case, add another point
                    t1000 = t(1) + 1000.;
                    time_array = [time_array, t1000];
                    data_array = [data_array(1), data_array(1)];                    
                end
                
                % Add data for t = 0. if none using linear extrapolation of
                % first 2 data points
                if time_array(1) > 0.

                    if interpolate    % add 1 point at time 0
                        x = [time_array(1), time_array(2)];
                        y = [data_array(1), data_array(2)];
                        d0 = interp1(x, y, 0.,'linear','extrap');                        
                        time_array = [0., time_array];
                        data_array = [d0, data_array];
                    else  % add 2 data points
                        time_array = [0., time_array(1), time_array];
                        data_array = [0., 0.,  data_array];                        
                    end
                end
                
                % handling blk.OutputAfterFinalValue
                blkParams = struct;
                blkParams.OutputAfterFinalValue = blk.OutputAfterFinalValue;
                blkParams.blk_name = blk_name;
                [time_array, data_array] = ...
                    FromWorkspace_To_Lustre.handleOutputAfterFinalValue(...
                    time_array, data_array, SampleTime, ...
                    blkParams.OutputAfterFinalValue);
%                 t_final = time_array(end)*1.e3;
%                 if strcmp(blk.OutputAfterFinalValue, 'Extrapolation')
%                     x = [time_array(end-1), time_array(end)];
%                     y = [data_array(end-1), data_array(end)];
%                     df = interp1(x, y, t_final,'linear','extrap');
%                     time_array = [time_array, t_final];
%                     data_array = [data_array, df];
%                 elseif strcmp(blk.OutputAfterFinalValue, 'Setting to zero')
%                     t_next = time_array(end)+0.5*SampleTime;
%                     time_array = [time_array, t_next];
%                     data_array = [data_array, 0.0];
%                     time_array = [time_array, t_final];
%                     data_array = [data_array, 0.0];
%                 elseif strcmp(blk.OutputAfterFinalValue, 'Holding final value')
%                     time_array = [time_array, t_final];
%                     data_array = [data_array, data_array(end)];
%                 else   % Cyclic repetition not supported
%                     display_msg(sprintf('Option %s is not supported in block %s',...
%                         blk.OutputAfterFinalValue, HtmlItem.addOpenCmd(blk.Origin_path)), ...
%                         MsgType.ERROR, 'FromWorkspace_To_Lustre', '');
%                     return;
%                 end
                
                if numel(outputs) >= i                    
                    [codeAst, vars] = ...
                        Sigbuilderblock_To_Lustre.interpTimeSeries(...
                        outputs{i},time_array, data_array, ...
                        blkParams,i,interpolate, simTime,backend);
                 
                    codeAst_all = [codeAst_all codeAst];
                    vars_all = [vars_all vars];
                end
            end
            external_lib = {'LustMathLib_abs_real'};
            obj.addExternal_libraries(external_lib);
            obj.setCode( codeAst_all );      
            obj.addVariable(outputs_dt);
            obj.addVariable(vars_all);       
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            VariableName = blk.VariableName;
            [variable, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, VariableName);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    VariableName, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
%             t = [0, 0];
%             if isnumeric(variable)
%                 t = variable(:,1);
%             elseif isstruct(variable)
%                 t = variable.time;
%             elseif isa(variable,'timeseries')
%                 t = variable.Time;
            if ~isnumeric(variable) & ~isstruct(variable) & ~isa(variable,'timeseries')
                obj.addUnsupported_options(...
                    sprintf('Workspace variable must be numeric arrays, time series or struct with time and data in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            %unsupported options
            if strcmp(blk.OutputAfterFinalValue, 'Cyclic repetition')
                obj.addUnsupported_options(...
                    sprintf('Option %s is not supported in block %s',...
                    blk.OutputAfterFinalValue, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            % What if Sample Time of block variable is different from Model ST 
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods (Static)
        
        function [time_array, data_array] = handleOutputAfterFinalValue(...
                time_array, data_array, SampleTime, option)
            % handling blk.OutputAfterFinalValue
            t_final = time_array(end)*1.e3;
            if strcmp(option, 'Extrapolation')
                x = [time_array(end-1), time_array(end)];
                y = [data_array(end-1), data_array(end)];
                df = interp1(x, y, t_final,'linear','extrap');
                time_array = [time_array, t_final];
                data_array = [data_array, df];
            elseif strcmp(option, 'Setting to zero')
                t_next = time_array(end)+0.5*SampleTime;
                time_array = [time_array, t_next];
                data_array = [data_array, 0.0];
                time_array = [time_array, t_final];
                data_array = [data_array, 0.0];
            elseif strcmp(option, 'Holding final value')
                time_array = [time_array, t_final];
                data_array = [data_array, data_array(end)];
            else   % Cyclic repetition not supported
                display_msg(sprintf('Option %s is not supported in block %s',...
                    option, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'FromWorkspace_To_Lustre', '');
                return;
            end
        end
        
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

