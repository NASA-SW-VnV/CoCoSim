classdef Outport_To_Lustre < Block_To_Lustre
    %Outport_To_Lustre translates the Outport block
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
            [outputs, ~] = SLX2LusUtils.getBlockOutputsNames(blk);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            codes = {};
            enabled_cond = '';
            if isfield(blk, 'isEnabled') && blk.isEnabled == 1
                lus_outputDataType = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{1});
                if strcmp(blk.InitialOutput, '[]')
                    InitialOutput = '0';
                else
                    InitialOutput = blk.InitialOutput;
                end
                [InitialOutputValue, InitialOutputType, status] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, InitialOutput);
                if status
                    display_msg(sprintf('InitialOutput %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        blk.InitialOutput, blk.Origin_path), ...
                        MsgType.ERROR, 'Outport_To_Lustre', '');
                    return;
                end
                [value_inlined, status, msg] = MatlabUtils.inline_values(InitialOutputValue);
                if status
                    %message
                    display_msg(msg,MsgType.ERROR, 'Outport_To_Lustre', '');
                    return;
                end
                InitialOutput_str = {};
                for i=1:numel(value_inlined)
                    if strcmp(lus_outputDataType, 'real')
                        InitialOutput_str{i} = sprintf('%.15f', value_inlined(i));
                    elseif strcmp(lus_outputDataType, 'int')
                        InitialOutput_str{i} = sprintf('%d', int32(value_inlined(i)));
                    elseif strncmp(InitialOutputType, 'int', 3) ...
                            || strncmp(InitialOutputType, 'uint', 4)
                        InitialOutput_str{i} = num2str(value_inlined(i));
                    elseif strcmp(InitialOutputType, 'boolean') || strcmp(InitialOutputType, 'logical')
                        if value_inlined(i)
                            InitialOutput_str{i} = 'true';
                        else
                            InitialOutput_str{i} = 'false';
                        end
                    else
                        InitialOutput_str{i} = sprintf('%.15f', value_inlined(i));
                    end
                end
                if numel(InitialOutput_str) < numel(outputs)
                    InitialOutput_str = arrayfun(@(x) {InitialOutput_str{1}}, (1:numel(outputs)));
                end
                
                for i=1:numel(outputs)
                    if strcmp(blk.OutputWhenDisabled, 'reset')
                        out_Y0 = InitialOutput_str{i};
                    else
                        out_Y0 = sprintf('%s -> pre(%s)',...
                            InitialOutput_str{i}, outputs{i});
                    end
                    enabled_cond{i} = sprintf('if not %s then %s else ', ...
                        SLX2LusUtils.isEnabledStr(), out_Y0);
                end
            else
                for i=1:numel(outputs)
                    enabled_cond{i} = '';
                end
            end
            for i=1:numel(outputs)
                codes{i} = sprintf('%s = %s %s;\n\t', outputs{i}, enabled_cond{i}, inputs{i});
            end
            
            obj.setCode( MatlabUtils.strjoin(codes, ''));
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
    end
    
end

