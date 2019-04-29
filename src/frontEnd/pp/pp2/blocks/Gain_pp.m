function [status, errors_msg] = Gain_pp(model)
% Gain_pp Searches for gain blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing Gain blocks
status = 0;
errors_msg = {};

Gain_list = find_system(model, ...
    'LookUnderMasks', 'all', 'BlockType','Gain');
if not(isempty(Gain_list))
    display_msg('Replacing Gain blocks...', MsgType.INFO,...
        'Gain_pp', '');
    for i=1:length(Gain_list)
        try
            display_msg(Gain_list{i}, MsgType.INFO, ...
                'Gain_pp', '');
            gain = get_param(Gain_list{i},'Gain');
            [gain_value, ~, status] = SLXUtils.evalParam(...
                model, ...
                get_param(Gain_list{i}, 'Parent'), ...
                Gain_list{i}, ...
                gain);
            if status == 0 && numel(gain_value) == 1
                continue;
            end
            CompiledPortDataTypes = SLXUtils.getCompiledParam(Gain_list{i}, 'CompiledPortDataTypes');
            if strcmp(CompiledPortDataTypes.Inport{1}, 'boolean') ...
                    && ~MatlabUtils.contains(CompiledPortDataTypes.Outport{1}, 'fix')
                outputDataType = CompiledPortDataTypes.Outport{1};
            else
                outputDataType = get_param(Gain_list{i}, 'OutDataTypeStr');
            end
            Multiplication = get_param(Gain_list{i}, 'Multiplication');
            SaturateOnIntegerOverflow = get_param(Gain_list{i},'SaturateOnIntegerOverflow');
            if strcmp(Multiplication, 'Element-wise(K.*u)')
                pp_name = 'gain_ElementWise';
            elseif strcmp(Multiplication, 'Matrix(K*u)') ...
                    || strcmp(Multiplication, 'Matrix(K*u) (u vector)')
                pp_name = 'gain_K_U';
            elseif strcmp(Multiplication, 'Matrix(u*K)')
                pp_name = 'gain_U_K';
            end
            OutMin = get_param(Gain_list{i}, 'OutMin');
            OutMax = get_param(Gain_list{i}, 'OutMax');
            % replace block
            PP2Utils.replace_one_block(Gain_list{i},fullfile('pp_lib',pp_name));
            
            % set parameters to constant block
            set_param(strcat(Gain_list{i},'/K'),...
                'Value',gain);
            set_param(strcat(Gain_list{i},'/K'),...
                'OutDataTypeStr','Inherit: Inherit via back propagation');
            if strcmp(Multiplication, 'Element-wise(K.*u)')
                set_param(strcat(Gain_list{i},'/K'),...
                'VectorParams1D','on');
            end
            
            % set parameters to product block
            if strcmp(outputDataType, 'Inherit: Same as input')
                outputDataType = 'Inherit: Same as first input';
            end
            set_param(strcat(Gain_list{i},'/Product'),...
                'OutDataTypeStr',outputDataType);
            set_param(strcat(Gain_list{i},'/Product'),...
                'SaturateOnIntegerOverflow',SaturateOnIntegerOverflow);
            
            set_param(strcat(Gain_list{i},'/Out1'), 'OutMin', OutMin);
            set_param(strcat(Gain_list{i},'/Out1'), 'OutMax', OutMax);
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'Gain_pp', '');
            status = 1;
            errors_msg{end + 1} = sprintf('Gain pre-process has failed for block %s', Gain_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'Gain_pp', '');
end

end

