function [ lustre_code ] = getExternalLibrariesNodes( external_libraries )
[ lustre_code, open_list ] = recursive_call( external_libraries, {} );
if ~isempty(open_list)
    open_list = unique(open_list);
    open_list = cellfun(@(x) sprintf('#open <%s>\n',x), open_list, 'un', 0);
    lustre_code = [ MatlabUtils.strjoin(open_list, ''), lustre_code];
end
end

function [ lustre_code, open_list ] = recursive_call( external_libraries, already_handled )
%GETEXTERNALLIBRARIESNODES returns the lustre nodes and libraries to be add
%to the head of lustre code.
lustre_code = '';
open_list = {};
if isempty(external_libraries)
    return;
end

external_libraries = unique(external_libraries);
additional_nodes = {};
for i=1:numel(external_libraries)
    lib = external_libraries{i};
    if strncmp(lib, 'KIND2', 5)
        lib = strrep(lib, 'KIND2_', '');
        fun_name = sprintf('KIND2MathLib.get_%s',lib);
        fun_handle = str2func(fun_name);
        try
            [node, external_nodes_i] = fun_handle();
        catch
            display_msg(sprintf('Library %s not supported', lib),...
                MsgType.ERROR, 'getExternalLibrariesNodes','');
            continue;
        end
        lustre_code = [node, lustre_code];
        additional_nodes = [additional_nodes, external_nodes_i];
    else
        fun_name = sprintf('ExtLib.get_%s',lib);
        fun_handle = str2func(fun_name);
        try
            [node, external_nodes_i, opens] = fun_handle();
        catch
            display_msg(sprintf('Library %s not supported', lib),...
                MsgType.ERROR, 'getExternalLibrariesNodes','');
            continue;
        end
        lustre_code = [node, lustre_code];
        open_list = [open_list, opens];
        additional_nodes = [additional_nodes, external_nodes_i];
    end
    
end

already_handled = unique([already_handled, external_libraries]);
additional_nodes = unique(additional_nodes);
additional_nodes = additional_nodes(~ismember(additional_nodes, already_handled));
[ additional_code, additional_open_list ] = recursive_call( additional_nodes, already_handled );
lustre_code = [additional_code, lustre_code];
open_list = [open_list, additional_open_list];


end

