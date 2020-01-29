function [main_node, external_nodes, external_libraries] = ...
        stateflowCode(ss_ir, xml_trace)
    %% Statflow support: use old compiler from github
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       
    %
    %
    external_nodes = {};
    external_libraries = {};
    rt = sfroot;
    m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name',bdroot(ss_ir.Origin_path));
    chart = m.find('-isa','Stateflow.Chart', 'Path', ss_ir.Origin_path);
    [ char_node, extern_Stateflow_nodes_fun] = write_Chart( chart, 0, xml_trace,'' );
    node_name = get_full_name( chart, true );
    main_node = nasa_toLustre.lustreAst.RawLustreCode(sprintf(char_node), node_name);
    if isempty(extern_Stateflow_nodes_fun)
        return;
    end
    [~, I] = unique({extern_Stateflow_nodes_fun.Name});
    extern_Stateflow_nodes_fun = extern_Stateflow_nodes_fun(I);
    for i=1:numel(extern_Stateflow_nodes_fun)
        fun = extern_Stateflow_nodes_fun(i);
        if strcmp(fun.Name,'trigo')
            external_libraries{end + 1} = 'LustMathLib_lustrec_math';
        elseif strcmp(fun.Name,'lustre_math_fun')
            external_libraries{end + 1} = 'LustMathLib_lustrec_math';
        elseif strcmp(fun.Name,'lustre_conv_fun')
            external_libraries{end + 1} = 'LustDTLib_conv';
        elseif strcmp(fun.Name,'after')
            external_nodes{end + 1} = nasa_toLustre.lustreAst.RawLustreCode(sprintf(temporal_operators(fun)), 'after');
        elseif strcmp(fun.Name, 'min') && strcmp(fun.Type, 'int*int')
            external_libraries{end + 1} = 'LustMathLib_min_int';
        elseif strcmp(fun.Name, 'min') && strcmp(fun.Type, 'real*real')
            external_libraries{end + 1} = 'LustMathLib_min_real';
        elseif strcmp(fun.Name, 'max') && strcmp(fun.Type, 'int*int')
            external_libraries{end + 1} = 'LustMathLib_max_int';
        elseif strcmp(fun.Name, 'max') && strcmp(fun.Type, 'real*real')
            external_libraries{end + 1} = 'LustMathLib_max_real';
        end
    end
end


