
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Get the initial ouput of Outport depending on the dimension.
% the function returns a list of LustreExp objects: IntExpr,
% RealExpr or BooleanExpr
function InitialOutput_cell = getInitialOutput(parent, blk, InitialOutput, slx_dt, max_width)
    
    [lus_outputDataType] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
    if strcmp(InitialOutput, '[]')
        InitialOutput = '0';
    end
    [InitialOutputValue, InitialOutputType, status] = ...
        nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, InitialOutput);
    if status
        display_msg(sprintf('InitialOutput %s in block %s not found neither in Matlab workspace or in Model workspace',...
            InitialOutput, blk.Origin_path), ...
            MsgType.ERROR, 'Outport_To_Lustre', '');
        return;
    end
    if iscell(lus_outputDataType)...
            && numel(InitialOutputValue) < numel(lus_outputDataType)
        % in the case of bus type, lus_outputDataType is inlined to
        % the basic types of the bus. We need to inline
        % InitialOutputValue as well
        InitialOutputValue = arrayfun(@(x) InitialOutputValue(1), (1:numel(lus_outputDataType)*max_width));
        base_lus_outputDataType = lus_outputDataType;
        for i=2:max_width
            lus_outputDataType = [lus_outputDataType, base_lus_outputDataType];
        end
    else
        lus_outputDataType = arrayfun(@(x) {lus_outputDataType}, (1:numel(InitialOutputValue)));
    end
    %
    InitialOutput_cell = cell(1, numel(InitialOutputValue));
    for i=1:numel(InitialOutputValue)
        InitialOutput_cell{i} = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
            InitialOutputValue(i), lus_outputDataType{i}, InitialOutputType);
    end

    if numel(InitialOutput_cell) < max_width
        InitialOutput_cell = arrayfun(@(x) InitialOutput_cell(1), (1:max_width));
    end

end
