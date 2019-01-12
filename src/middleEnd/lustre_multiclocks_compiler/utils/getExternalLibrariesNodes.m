function [ lustre_nodes , open_list, abstractedNodes] = getExternalLibrariesNodes( external_libraries , lus_backend )
[ lustre_nodes, open_list, abstractedNodes ] = recursive_call( external_libraries, {} ,lus_backend);
if ~isempty(open_list)
    open_list = unique(open_list);
end
if ~isempty(abstractedNodes)
    abstractedNodes = unique(abstractedNodes);
end
end

function [ lustre_nodes, open_list, abstractedNodes ] = recursive_call( external_libraries, already_handled, lus_backend )
%GETEXTERNALLIBRARIESNODES returns the lustre nodes and libraries to be add
%to the head of lustre code.
lustre_nodes = {};
open_list = {};
abstractedNodes = {};
if isempty(external_libraries)
    return;
end

external_libraries = unique(external_libraries);
additional_nodes = {};
for i=1:numel(external_libraries)
    lib = external_libraries{i};
    if strncmp(lib, 'KIND2MathLib', 12)
        lib = strrep(lib, 'KIND2MathLib_', '');
        fun_name = sprintf('KIND2MathLib.get_%s',lib);
    elseif strncmp(lib, 'LustMathLib', 11)
        lib = strrep(lib, 'LustMathLib_', '');
        fun_name = sprintf('LustMathLib.get_%s',lib);
    elseif strncmp(lib, 'LustDTLib', 9)
        lib = strrep(lib, 'LustDTLib_', '');
        fun_name = sprintf('LustDTLib.get_%s',lib);
    elseif strncmp(lib, 'BlocksLib', 9)
        lib = strrep(lib, 'BlocksLib_', '');
        fun_name = sprintf('BlocksLib.get_%s',lib);
    else
        fun_name = sprintf('ExtLib.get_%s',lib);
    end
    try
        fun_handle = str2func(fun_name);
        [node, external_nodes_i, opens, abstracts] = fun_handle(lus_backend);
    catch
        display_msg(sprintf('Library %s not supported', lib),...
            MsgType.ERROR, 'getExternalLibrariesNodes','');
        continue;
    end
    if ischar(node)
        lustre_nodes{end + 1} = RawLustreCode(node, lib);
    else
        lustre_nodes{end + 1} = node;
    end
    open_list = [open_list, opens];
    abstractedNodes = [abstractedNodes, abstracts];
    additional_nodes = [additional_nodes, external_nodes_i];
end

already_handled = unique([already_handled, external_libraries]);
additional_nodes = unique(additional_nodes);
additional_nodes = additional_nodes(~ismember(additional_nodes, already_handled));
[ additional_code, additional_open_list, additional_abstractedNodes ] = recursive_call( additional_nodes, already_handled,lus_backend );
lustre_nodes = [additional_code, lustre_nodes];
open_list = [open_list, additional_open_list];
abstractedNodes = [abstractedNodes, additional_abstractedNodes];

end

