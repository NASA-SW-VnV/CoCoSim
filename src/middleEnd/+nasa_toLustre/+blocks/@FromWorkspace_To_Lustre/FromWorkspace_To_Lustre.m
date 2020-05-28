%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef FromWorkspace_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %FromWorkspace_To_Lustre
   
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ~, main_sampleTime, varargin)
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            
            
            % get Interpolate parameter
            interpolate = strcmp(blk.Interpolate, 'on');
            outputAfterFinalValue = blk.OutputAfterFinalValue;
            % get VariableName parameter
            [variable, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.VariableName);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab/Model/Mask workspace',...
                    blk.VariableName, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            % get output datatype
            slx_outDataType = blk.CompiledPortDataTypes.Outport{1};
            [outLusDT, ~, ~] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_outDataType);
            if interpolate || strcmp(outputAfterFinalValue, 'Extrapolation')
                v_lusDT = 'real';
                v_slxDT = 'double';
            else
                v_lusDT = outLusDT;
                v_slxDT = slx_outDataType;
            end
            if isnumeric(variable)
                % for matrix
                [~, ncol] = size(variable);
                time = variable(:,1);
                values = variable(:,2:ncol);
            elseif isa(variable,'timeseries')
                time = variable.Time;
                values = variable.Data;
            elseif isstruct(variable)
                % for struct
                time = variable.time;
                values = variable.signals.values;
            else
                display_msg(sprintf('Workspace variable must be numeric arrays or struct in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'FromWorkspace_To_Lustre', '');
                return;
            end
            
            
            % In FromWorkspace block :LENGTH(time) and SIZE(values,last_dimension) must be the same.
            % we gonna change values to match LENGTH(time) == SIZE(values,1)
            if ~ismatrix(values)
                n = ndims(values);
                % shift dimensions to the right by 1
                values = permute(values, [n (1:n-1)]);
            end
            % reshapre values to 2D
            [n, m] = size(values);
            values = reshape(values, [n, m]);
            % change time to column
            if isrow(time)
                time = time';
            end
            if time(1) ~= 0
                % add value at time zero
                if interpolate
                    zero_value = interp1(time, values, 0, 'linear', 'extrap');
                else
                    zero_value = zeros(1, m);
                end
                
                time = [0; time];
                values = [zero_value; values];
            end
            
            
            if strcmp(outputAfterFinalValue, 'Cyclic repetition')
                % Cyclic repetition not supported
                %% TODO(HAMZA) support it with "every" operator
                display_msg(sprintf('Option %s is not supported in block %s',...
                    blk.OutputAfterFinalValue, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'FromWorkspace_To_Lustre', '');
                return;
            end
            outputs_conds = {};
            outputs_thens = {};
            simTime = nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr());
            
            un_time = unique(time); % remove repetition for SignalBuilder case
            shifted_time = [0; un_time(1:end-1)];
            distance = un_time - shifted_time;
            distance(1) = main_sampleTime(1);% replace first distance by model sample time
            epsilon = min(distance)/1000;
            for i=1:length(time)-1
                if time(i) == time(i+1)
                    % the case of fromworkspace that is inside SignalBuilder
                    % when t(n) = t(n+1), t(n) is used to interpolate left
                    % values and t(n+1) is used to interpolate right
                    % values. the value at t(n)=t(n+1) will be V(n+1).
                    continue;
                end
                t = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                    time(i),  'real');
                t_plus_1 = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                    time(i+1), 'real');
                
                
                lowerOP = nasa_toLustre.lustreAst.BinaryExpr.GTE;
                lowerCond = nasa_toLustre.lustreAst.BinaryExpr(...
                    lowerOP, simTime, t, [],...
                    coco_nasa_utils.LusBackendType.isLUSTREC(lus_backend), epsilon);
                
                upperOP = nasa_toLustre.lustreAst.BinaryExpr.LT;
                upperCond = nasa_toLustre.lustreAst.BinaryExpr(...
                    upperOP, simTime, t_plus_1, [], ...
                    coco_nasa_utils.LusBackendType.isLUSTREC(lus_backend), epsilon);
                
                outputs_conds{end+1} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.AND, lowerCond, upperCond);
                thens = cell(1, length(outputs));
                if interpolate
                    for outIdx = 1:length(outputs)
                        v = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                            values(i, outIdx), v_lusDT, v_slxDT);
                        v_plus_1 = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                            values(i+1, outIdx), v_lusDT, v_slxDT);
                        thens{outIdx} = ...
                            nasa_toLustre.blocks.Lookup_nD_To_Lustre.interp2points_2D(...
                            t, v, t_plus_1, v_plus_1, simTime);
                    end
                else
                    for outIdx = 1:length(outputs)
                        thens{outIdx} = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                            values(i, outIdx), v_lusDT, v_slxDT);
                    end
                end
                if length(outputs) == 1
                    outputs_thens{end+1} = thens{1};
                else
                    outputs_thens{end+1} = nasa_toLustre.lustreAst.TupleExpr(thens);
                end
            end
            
            % t > stop_time
            
            if strcmp(outputAfterFinalValue, 'Extrapolation')
                % extrapolate using last two points
                t = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                    time(end-1),  'real');
                t_plus_1 = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                    time(end),  'real');
                thens = cell(1, length(outputs));
                for outIdx = 1:length(outputs)
                    v = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                        values(end-1, outIdx), v_lusDT, v_slxDT);
                    v_plus_1 = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                        values(end, outIdx), v_lusDT, v_slxDT);
                    thens{outIdx} = ...
                        nasa_toLustre.blocks.Lookup_nD_To_Lustre.interp2points_2D(...
                        t, v, t_plus_1, v_plus_1, simTime);
                end
                if length(outputs) == 1
                    outputs_thens{end+1} = thens{1};
                else
                    outputs_thens{end+1} = nasa_toLustre.lustreAst.TupleExpr(thens);
                end
                
            elseif strcmp(outputAfterFinalValue, 'Setting to zero')
                % add code t = tlast => v = vlast
                t = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                    time(end),  'real');
                outputs_conds{end+1} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
                    simTime, ...
                    t, [], coco_nasa_utils.LusBackendType.isLUSTREC(lus_backend), epsilon);
                thens = cell(1, length(outputs));
                for outIdx = 1:length(outputs)
                    thens{outIdx} = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                        values(end, outIdx), v_lusDT, v_slxDT);
                end
                if length(outputs) == 1
                    outputs_thens{end+1} = thens{1};
                else
                    outputs_thens{end+1} = nasa_toLustre.lustreAst.TupleExpr(thens);
                end
                % add code t > t_last => v = 0
                thens = cell(1, length(outputs));
                for outIdx = 1:length(outputs)
                    thens{outIdx} = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                        0, v_lusDT, v_slxDT);
                end
                if length(outputs) == 1
                    outputs_thens{end+1} = thens{1};
                else
                    outputs_thens{end+1} = nasa_toLustre.lustreAst.TupleExpr(thens);
                end
            elseif strcmp(outputAfterFinalValue, 'Holding final value')
                % add condition t >= t_last => v = vlast
                thens = cell(1, length(outputs));
                for outIdx = 1:length(outputs)
                    thens{outIdx} = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                        values(end, outIdx), v_lusDT, v_slxDT);
                end
                if length(outputs) == 1
                    outputs_thens{end+1} = thens{1};
                else
                    outputs_thens{end+1} = nasa_toLustre.lustreAst.TupleExpr(thens);
                end
                
            end
            if length(outputs) == 1
                lhs = outputs{1};
            else
                lhs = nasa_toLustre.lustreAst.TupleExpr(outputs);
            end
            
            % add seperate node and call it. add contract bounding values.
            blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            ext_node = nasa_toLustre.lustreAst.LustreNode();
            ext_node.setName(blk_name);
            ext_node.setInputs(nasa_toLustre.lustreAst.LustreVar(simTime, 'real'));
            ext_node_outputs = outputs_dt;
            if ~strcmp(v_lusDT, outLusDT)
                % need casting from real to slx datatype
                ext_node_outputs = cellfun(@(x) ...
                    nasa_toLustre.lustreAst.LustreVar(x, 'real'), outputs,...
                    'UniformOutput', 0);
            end
            ext_node.setOutputs(ext_node_outputs);
            body{1} = nasa_toLustre.lustreAst.LustreEq(...
                lhs, ...
                nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(...
                outputs_conds, outputs_thens));
            ext_node.setBodyEqs(body);
            
            obj.addExtenal_node(ext_node);
            if strcmp(v_lusDT, outLusDT)
                obj.addCode(nasa_toLustre.lustreAst.LustreEq(lhs, ...
                    nasa_toLustre.lustreAst.NodeCallExpr(...
                    blk_name, simTime)));
            else
                % need casting
                [external_lib, conv_format] =...
                    nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                    'real', slx_outDataType, 'Nearest');
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                    local_vars = cellfun(@(x) ...
                        nasa_toLustre.lustreAst.LustreVar(...
                        strcat(blk_name, '_', x.getId()), 'real'), outputs,...
                        'UniformOutput', 0);
                    obj.addVariable(local_vars);
                    local_Ids = cellfun(@(x) ...
                        nasa_toLustre.lustreAst.VarIdExpr(x.getId()), local_vars,...
                        'UniformOutput', 0);
                    if length(local_Ids) == 1
                        new_lhs = local_Ids{1};
                    else
                        new_lhs = nasa_toLustre.lustreAst.TupleExpr(local_Ids);
                    end
                    obj.addCode(nasa_toLustre.lustreAst.LustreEq(new_lhs, ...
                        nasa_toLustre.lustreAst.NodeCallExpr(...
                        blk_name, simTime)));
                    
                    %add casting
                    for i=1:length(outputs)
                        code = ...
                            nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                            conv_format,local_Ids{i});
                        obj.addCode(nasa_toLustre.lustreAst.LustreEq(outputs{i}, code));
                    end
                end
            end
            % add abs real for epsilon comparaison if backend is LUstrec
            if coco_nasa_utils.LusBackendType.isLUSTREC(lus_backend)
                obj.addExternal_libraries('LustMathLib_abs_real');
            end
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            obj.unsupported_options = {};
            VariableName = blk.VariableName;
            [variable, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, VariableName);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    VariableName, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            if ~isnumeric(variable) && ~isstruct(variable) && ~isa(variable,'timeseries')
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
            %% TODO: What if Sample Time of block variable is different from Model ST
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods (Static)
        
        [time_array, data_array] = handleOutputAfterFinalValue(...
            time_array, data_array, SampleTime, option)
        
        
    end
end

