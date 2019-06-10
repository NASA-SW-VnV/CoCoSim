function vars = getDataVars(d_list)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    vars = {};
    for i=1:numel(d_list)
        names = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataName(d_list{i});
        lusDt = d_list{i}.LusDatatype;
        vars = MatlabUtils.concat(vars, ...
            cellfun(@(x) nasa_toLustre.lustreAst.LustreVar(x, lusDt), ...
            names, 'UniformOutput', false));
    end
end
