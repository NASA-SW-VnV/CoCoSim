%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% construct_EMF_verif_model
function status = check_DType_and_Dimensions(slx_file_name)
    status = 0;
    sys_list = find_system(slx_file_name, 'LookUnderMasks', 'all',...
        'RegExp', 'on', 'OutDataTypeStr', '[u]?int(8|16)');
    if ~isempty(sys_list)
        msg = sprintf('Model contains integers ports differens than int32.');
        msg = [msg, 'Lus2slx current version support only int32 dataType'];
        display_msg(msg, MsgType.ERROR, ...
            'LustrecUtils.check_DType_and_Dimensions','');
        status = 1;
        return;
    end
    % Dimensions should be less than 2
    inport_list = find_system(slx_file_name, 'SearchDepth', 1, 'BlockType', 'Inport');
    try
        code_on=sprintf('%s([], [], [], ''compile'')', slx_file_name);
        eval(code_on);
    catch
    end
    dimensions = get_param(inport_list, 'CompiledPortDimensions');
    outport_dimensions = cellfun(@(x) x.Outport, dimensions, 'un', 0);
    for i=1:numel(outport_dimensions)
        dim = outport_dimensions{i};
        if numel(dim) > 3


            msg = sprintf('Invalid inport dimension "%s" with dimension %s: Lus2slx functions does not support dimension > 2.',...
                inport_list{i}, num2str(dim));
            display_msg(msg, MsgType.ERROR, ...
                'LustrecUtils.check_DType_and_Dimensions','');
            status = 1;
            break;


        end
    end
    code_off=sprintf('%s([], [], [], ''term'')', slx_file_name);
    eval(code_off);
end

