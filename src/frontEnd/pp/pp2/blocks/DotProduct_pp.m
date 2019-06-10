function [status, errors_msg] = DotProduct_pp(model)
    % substitute_product_process Searches for DotProduct blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Processing DotProduct blocks
    
    status = 0;
    errors_msg = {};
    
    DotProduct_list = find_system(model, ...
        'LookUnderMasks', 'all', 'BlockType','DotProduct');
    if not(isempty(DotProduct_list))
        display_msg('Replacing DotProduct blocks...', MsgType.INFO,...
            'DotProduct_process', '');
        for i=1:length(DotProduct_list)
            display_msg(DotProduct_list{i}, MsgType.INFO, ...
                'DotProduct_process', '');
            try
                %DotProduct = get_param(DotProduct_list{i},'DotProduct');
                pp_name = 'DotProduct';
                outputDataType = get_param(DotProduct_list{i}, 'OutDataTypeStr');
                RndMeth = get_param(DotProduct_list{i}, 'RndMeth');
                OutMin = get_param(DotProduct_list{i}, 'OutMin');
                OutMax = get_param(DotProduct_list{i}, 'OutMax');
                InputSameDT = get_param(DotProduct_list{i}, 'InputSameDT');
                SaturateOnIntegerOverflow = get_param(DotProduct_list{i}, 'SaturateOnIntegerOverflow');
                LockScale = get_param(DotProduct_list{i}, 'LockScale');
                
                % set port dimensions: in case one of the inports dimensions is "-1".
                try
                    portHandles = get_param(DotProduct_list{i}, 'PortHandles');
                    dim1 = SLXUtils.getCompiledParam(portHandles.Inport(1), 'CompiledPortDimensions');
                    dim1 = dim1(2:end);% remove first element that says how many dimensions exists.
                    port1CompiledDim = mat2str(dim1);
                    
                    dim2 = SLXUtils.getCompiledParam(portHandles.Inport(2), 'CompiledPortDimensions');
                    dim2 = dim2(2:end);% remove first element that says how many dimensions exists.
                    port2CompiledDim = mat2str(dim2);
                catch
                    port1CompiledDim = '-1';
                    port2CompiledDim = '-1';
                end
                PP2Utils.replace_one_block(DotProduct_list{i},fullfile('pp_lib',pp_name));
                set_param(strcat(DotProduct_list{i},'/Product'),...
                    'OutDataTypeStr',outputDataType);
                set_param(strcat(DotProduct_list{i},'/Product'),...
                    'RndMeth',RndMeth);
                set_param(strcat(DotProduct_list{i},'/Sum'),...
                    'OutDataTypeStr',outputDataType);
                set_param(strcat(DotProduct_list{i},'/Sum'),...
                    'RndMeth',RndMeth);
                
                set_param(strcat(DotProduct_list{i},'/Sum'),...
                    'OutMin',OutMin);
                set_param(strcat(DotProduct_list{i},'/Sum'),...
                    'OutMax',OutMax);
                
                set_param(strcat(DotProduct_list{i},'/Product'),...
                    'InputSameDT',InputSameDT);
                
                set_param(strcat(DotProduct_list{i},'/Product'),...
                    'SaturateOnIntegerOverflow',SaturateOnIntegerOverflow);
                set_param(strcat(DotProduct_list{i},'/Sum'),...
                    'SaturateOnIntegerOverflow',SaturateOnIntegerOverflow);
                
                set_param(strcat(DotProduct_list{i},'/Product'),...
                    'LockScale',LockScale);
                
                set_param(strcat(DotProduct_list{i},'/SSpec1'),...
                    'Dimensions',port1CompiledDim);
                set_param(strcat(DotProduct_list{i},'/SSpec2'),...
                    'Dimensions',port2CompiledDim);
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('DotProduct pre-process has failed for block %s', DotProduct_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'DotProduct_process', '');
    end
end

