function [] = replace_DTF_block(blk, U_dims_blk,num,denum )
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    if numel(denum) < numel(num)
        tempDenum = zeros(1,length(num));
        tempDenum(1:numel(denum)) = denum;
        denum = tempDenum;
    end

    % Computing state space representation
    [A,B,C,D]=tf2ss(num,denum);
    if isempty(A)
        A = '0';
    else
        A = mat2str(A);
    end
    if isempty(B)
        B = '0';
    else
        B = mat2str(B);
    end
    if isempty(C)
        C = '0';
    else
        C = mat2str(C);
    end
    if isempty(D)
        D = '0';
    else
        D = mat2str(D);
    end

    [n,~] = size(num);
    mutliNumerator = 0;
    if n>1
        mutliNumerator = 1;
    end

    InitialStates = get_param(blk,'InitialStates');
    outputDataType = get_param(blk, 'OutDataTypeStr');
    if strcmp(outputDataType, 'Inherit: Same as input')
        outputDataType = 'Inherit: Same as first input';
    end
    RndMeth = get_param(blk, 'RndMeth');
    ST = get_param(blk,'SampleTime');
    SaturateOnIntegerOverflow = get_param(blk,'SaturateOnIntegerOverflow');

    % replacing
    PPUtils.replace_one_block(blk,'pp_lib/DTF');
    %restoring info
    set_param(strcat(blk,'/DTFScalar/A'),...
        'Value',A);
    set_param(strcat(blk,'/DTFScalar/B'),...
        'Value',B);
    set_param(strcat(blk,'/DTFScalar/C'),...
        'Value',C);
    set_param(strcat(blk,'/DTFScalar/D'),...
        'Value',D);
    if mutliNumerator
        OutputHandles = get_param(strcat(blk,'/Y'), 'PortHandles');
        DTFHandles = get_param(strcat(blk,'/DTFScalar'), 'PortHandles');
        delete_block(strcat(blk,'/ReverseReshape'));
        line = get_param(OutputHandles.Inport(1), 'line');
        delete_line(line);
        line = get_param(DTFHandles.Outport(1), 'line');
        delete_line(line);
        add_line(blk, DTFHandles.Outport(1), OutputHandles.Inport(1), 'autorouting', 'on');
    else
        set_param(strcat(blk,'/ReverseReshape'),...
            'OutputDimensions',mat2str(U_dims_blk));
    end
    set_param(strcat(blk,'/DTFScalar/FinalSum'),...
        'RndMeth',RndMeth);
    set_param(strcat(blk,'/DTFScalar/FinalSum'),...
        'OutDataTypeStr',outputDataType);
    set_param(strcat(blk,'/DTFScalar/FinalSum'),...
        'SaturateOnIntegerOverflow',SaturateOnIntegerOverflow);
    try
        set_param(strcat(blk,'/DTFScalar/X0'),...
            'InitialCondition',InitialStates);
    catch
        set_param(strcat(blk,'/DTFScalar/X0'),...
            'X0',InitialStates);
    end
    set_param(strcat(blk,'/DTFScalar/X0'),...
        'SampleTime',ST);
end

