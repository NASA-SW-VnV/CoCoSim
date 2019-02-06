function [node, external_nodes_i, opens, abstractedNodes] = get_fmod(lus_backend)
    %TODO create fmod node for Kind2: z = (real((int x) * 1000 mod (int y) * 1000)/1000.0 ??
    opens = {'lustrec_math'};
    abstractedNodes = {};
    if ~LusBackendType.isLUSTREC(lus_backend)
        abstractedNodes = {'fmod'};
    end
    external_nodes_i = {};
    node = '';
end