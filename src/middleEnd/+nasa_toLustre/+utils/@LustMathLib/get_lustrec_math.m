function [node, external_nodes_i, opens, abstractedNodes] = get_lustrec_math(lus_backend)
    opens = {'lustrec_math'};
    abstractedNodes = {};
    if ~LusBackendType.isLUSTREC(lus_backend)
        abstractedNodes = {'lustrec_math library'};
    end
    external_nodes_i = {};
    node = '';
end