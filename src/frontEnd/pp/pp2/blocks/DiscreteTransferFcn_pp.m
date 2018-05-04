function [] = DiscreteTransferFcn_pp(model)
% DiscreteTransferFcn_pp searches for DiscreteTransferFcn_pp blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>, Trinh, Khanh V <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing Gain blocks
dtf_list = find_system(model,'LookUnderMasks', 'all', 'BlockType','DiscreteTransferFcn');
dtf_list = [dtf_list; find_system(model,'BlockType','TransferFcn')];
if not(isempty(dtf_list))
    display_msg('Replacing DiscreteTransferFcn blocks...', MsgType.INFO,...
        'DiscreteTransferFcn_pp', '');
    
    %% geting dimensions of U
    warning off;
    code_on=sprintf('%s([], [], [], ''compile'')', model);
    eval(code_on);
    try
        U_dims = {};
        for i=1:length(dtf_list)
            CompiledPortDimensions = get_param(dtf_list{i}, 'CompiledPortDimensions');
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(CompiledPortDimensions.Inport);
            if numel(in_matrix_dimension) > 1
                display_msg(sprintf('block %s has external numerator/denominator not supported',...
                     dtf_list{i}), ...
                    MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                U_dims{end+1} = [];
                continue;
            else
                U_dims{end+1} = in_matrix_dimension{1}.dims;
            end
        end
    catch me
        display_msg(me.getReport(), ...
                MsgType.DEBUG, 'DiscreteTransferFcn_pp', '');
        code_off = sprintf('%s([], [], [], ''term'')', model);
        eval(code_off);
        warning on;
        return;
    end
    code_off = sprintf('%s([], [], [], ''term'')', model);
    eval(code_off);
    warning on;
    
    %% pre-processing blocks
    for i=1:length(dtf_list)
        if isempty(U_dims{i}) 
            continue;
        end
        display_msg(dtf_list{i}, MsgType.INFO, ...
            'DiscreteTransferFcn_pp', '');

        InitialStates = get_param(dtf_list{i},'InitialStates');
        
        
        outputDataType = get_param(dtf_list{i}, 'OutDataTypeStr');
        if strcmp(outputDataType, 'Inherit: Same as input')
            outputDataType = 'Inherit: Same as first input';
        end
        RndMeth = get_param(dtf_list{i}, 'RndMeth');
        ST = get_param(dtf_list{i},'SampleTime');
        
        % Obtaining z-expression parameters
        denum_str = get_param(dtf_list{i}, 'Denominator');
        [denum, status] = SLXUtils.evalParam(model, denum_str);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                denum_str, dtf_list{i}), ...
                MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
            continue;
        end
        
        num_str = get_param(dtf_list{i}, 'Numerator');
        [num, status] = SLXUtils.evalParam(model, num_str);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                num_str, dtf_list{i}), ...
                MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
            continue;
        end
        [n,~] = size(num);
        mutliNumerator = 0;
        if n>1
            mutliNumerator = 1;
        end
        blocktype= get_param(dtf_list{i}, 'BlockType');
        if strcmp(blocktype, 'TransferFcn')
            try
                Hc = tf(num, denum);
                sampleT = SLXUtils.get_BlockDiagram_SampleTime(model);
                Hd = c2d(Hc,sampleT);
                num = Hd.Numerator{:};
                denum = Hd.Denominator{:};
            catch
                display_msg(sprintf('block %s is not supported. Please change it to DiscreteTransferFcn',...
                     dtf_list{i}), ...
                    MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                continue
            end
        end
        % Computing state space representation
        [A,B,C,D]=tf2ss(num,denum);
        
        A = mat2str(A);
        B = mat2str(B);
        C = mat2str(C);
        D = mat2str(D);
        
        % replacing
        replace_one_block(dtf_list{i},'pp_lib/DTF');
        
        %restoring info
        set_param(strcat(dtf_list{i},'/DTFScalar/A'),...
            'Value',A);
        set_param(strcat(dtf_list{i},'/DTFScalar/B'),...
            'Value',B);
        set_param(strcat(dtf_list{i},'/DTFScalar/C'),...
            'Value',C);
        set_param(strcat(dtf_list{i},'/DTFScalar/D'),...
            'Value',D);
        if mutliNumerator
            OutputHandles = get_param(strcat(dtf_list{i},'/Y'), 'PortHandles');
            DTFHandles = get_param(strcat(dtf_list{i},'/DTFScalar'), 'PortHandles');
            delete_block(strcat(dtf_list{i},'/ReverseReshape'));
            line = get_param(OutputHandles.Inport(1), 'line');
            delete_line(line);
            line = get_param(DTFHandles.Outport(1), 'line');
            delete_line(line);
            add_line(dtf_list{i}, DTFHandles.Outport(1), OutputHandles.Inport(1), 'autorouting', 'on');
        else
            set_param(strcat(dtf_list{i},'/ReverseReshape'),...
                'OutputDimensions',mat2str(U_dims{i}));  
        end
        set_param(strcat(dtf_list{i},'/DTFScalar/FinalSum'),...
            'RndMeth',RndMeth);
        set_param(strcat(dtf_list{i},'/DTFScalar/FinalSum'),...
            'OutDataTypeStr',outputDataType);
        try
            set_param(strcat(dtf_list{i},'/DTFScalar/X0'),...
                'InitialCondition',InitialStates);
        catch
            set_param(strcat(dtf_list{i},'/DTFScalar/X0'),...
                'X0',InitialStates);
        end
        set_param(strcat(dtf_list{i},'/DTFScalar/X0'),...
                'SampleTime',ST);
    end
    display_msg('Done\n\n', MsgType.INFO, 'DiscreteTransferFcn_pp', '');
end
end


