function [status, errors_msg] = Gain_pp(model)
% substitute_gain_process Searches for gain blocks and replaces them by a
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
        'Gain_process', '');
    for i=1:length(Gain_list)
        try
            display_msg(Gain_list{i}, MsgType.INFO, ...
                'Gain_process', '');
            gain = get_param(Gain_list{i},'Gain');
            CompiledPortDataTypes = SLXUtils.getCompiledParam(Gain_list{i}, 'CompiledPortDataTypes');
            if isequal(CompiledPortDataTypes.Inport{1}, 'boolean') ...
                    && ~contains(CompiledPortDataTypes.Outport{1}, 'fix')
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
            replace_one_block(Gain_list{i},fullfile('pp_lib',pp_name));
            set_param(strcat(Gain_list{i},'/K'),...
                'Value',gain);
            set_param(strcat(Gain_list{i},'/K'),...
                'OutDataTypeStr','Inherit: Inherit via back propagation');
 
            set_param(strcat(Gain_list{i},'/Product'),...
                'OutDataTypeStr',outputDataType);
            set_param(strcat(Gain_list{i},'/Product'),...
                'SaturateOnIntegerOverflow',SaturateOnIntegerOverflow);
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('Gain pre-process has failed for block %s', Gain_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'Gain_process', '');
end

end

