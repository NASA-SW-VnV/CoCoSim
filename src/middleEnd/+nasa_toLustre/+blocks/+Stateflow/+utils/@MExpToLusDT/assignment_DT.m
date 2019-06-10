function dt = assignment_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree.leftExp, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
end

