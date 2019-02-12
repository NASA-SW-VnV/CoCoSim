function [main_node, external_nodes, external_libraries_i] = getChartNodes(parent, blk, main_sampleTime, ...
        lus_backend, coco_backend, xml_trace)
    try
        TOLUSTRE_SF_COMPILER = evalin('base', 'TOLUSTRE_SF_COMPILER');
    catch
        TOLUSTRE_SF_COMPILER =2;
    end
    if TOLUSTRE_SF_COMPILER == 1
        % OLD compiler
        [main_node, ~, external_nodes, external_libraries_i] = ...
            SS_To_LustreNode.subsystem2node(parent, blk, main_sampleTime, ...
            false, lus_backend, coco_backend, xml_trace);
    else
        % new compiler
        [main_node, external_nodes, external_libraries_i ] = ...
            SF_To_LustreNode.chart2node(parent,  blk,  main_sampleTime, lus_backend, xml_trace);
    end
end

