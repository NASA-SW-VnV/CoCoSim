classdef PP_Utils
    
    methods (Static = true)
        function [ordered_functions, fcts_map]  = ...
                order_pp_functions(pp_order_map, pp_handled_blocks, pp_unhandled_blocks)
            
            
            if isempty(pp_order_map)
                warning('Order map ''pp_order_map'' has not been defined. Please check pp_order.m');
                pp_order_map = containers.Map();
            end
            if isempty(pp_handled_blocks)
                errordlg('Order map ''pp_handled_blocks'' has not been defined. Please check pp_order.m');
            end
            if isempty(pp_unhandled_blocks)
                pp_unhandled_blocks = {};
            end
            
            priorities = sort(cell2mat(pp_order_map.keys));
            if ~isempty(priorities)
                lowest_priority = priorities(end);
            else
                lowest_priority = 0;
            end
            
            % fct -> priority
            fcts_map = containers.Map('KeyType', 'char', 'ValueType', 'int32');
            
            fcts_map = PP_Utils.update_priority(fcts_map, pp_order_map);
            fcts_map = PP_Utils.extract_fcts(fcts_map, pp_handled_blocks, lowest_priority);
            fcts_map = PP_Utils.extract_fcts(fcts_map, pp_unhandled_blocks, -1);
            ordered_functions = PP_Utils.get_ordered_functions(fcts_map);
           
        end
        
        function ordered_functions = get_ordered_functions(fcts_map)
            % priority -> functions
            priority_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            for k= fcts_map.keys
                priority = fcts_map(k{1});
                if isKey(priority_map, priority)
                    priority_map(priority) = [priority_map(priority), k];
                else
                    priority_map(priority) = k;
                end
            end
            
            % order functions by priority and remove functions with -1 priority
            ordered_functions = {};
            keys = setdiff(sort(cell2mat(priority_map.keys)), -1);
            for key= keys
                v_list = priority_map(key);
                for i=1:numel(v_list)
                    ordered_functions{numel(ordered_functions) + 1} = v_list{i};
                end
                
            end
            
        end
        function ordered_fcts_map = extract_fcts(ordered_fcts_map, map, lowest_priority)
            for i=1:numel(map)
                [library_path, fname,ext] = fileparts(map{i});
                if contains(fname, '*')
                    files_struct = what(library_path);
                    if ~isempty(files_struct)
                        library_path = files_struct.path;
                        mfiles = dir([library_path, filesep, fname,ext]);
                        folder = library_path;
                        for j=1:numel(mfiles)
                            mpath = fullfile(folder, mfiles(j).name);
                            if isKey(ordered_fcts_map, mpath)
                                if ordered_fcts_map(mpath) == -1 || lowest_priority == -1
                                    ordered_fcts_map(mpath) = -1;
                                end
                            else
                                ordered_fcts_map(mpath) = lowest_priority;
                            end
                        end
                    end
                else
                    mpath = which(map{i});
                    if isempty(mpath)
                        msg = sprintf('File %s is not in Matlab path.', map{i});
                        display_msg(msg, MsgType.ERROR, 'order_pp_functions', '');
                        continue;
                    end
                    if isKey(ordered_fcts_map, mpath)
                        if ordered_fcts_map(mpath) == -1 || lowest_priority == -1
                            ordered_fcts_map(mpath) = -1;
                        end
                    else
                        ordered_fcts_map(mpath) = lowest_priority;
                    end
                end
            end
            
        end
        
        function ordered_fcts_map = update_priority(ordered_fcts_map, pp_order_map)
            for key= sort(cell2mat(pp_order_map.keys))
                v_list = pp_order_map(key);
                for i=1:numel(v_list)
                    [library_path, fname,ext] = fileparts(v_list{i});
                    if contains(fname, '*')
                        files_struct = what(library_path);
                        if ~isempty(files_struct)
                            library_path = files_struct.path;
                            mfiles = dir([library_path, filesep, fname,ext]);
                            folder = library_path;
                            for j=1:numel(mfiles)
                                mpath = fullfile(folder, mfiles(j).name);
                                if isKey(ordered_fcts_map, mpath)
                                    if ordered_fcts_map(mpath) == -1 || key == -1
                                        ordered_fcts_map(mpath) = -1;
                                    end
                                else
                                    ordered_fcts_map(mpath) = key;
                                end
                            end
                        end
                    else
                        mpath = which(v_list{i});
                        if isempty(mpath)
                            msg = sprintf('File %s is not in Matlab path.', v_list{i});
                            display_msg(msg, MsgType.ERROR, 'order_pp_functions', '');
                            continue;
                        end
                        if isKey(ordered_fcts_map, mpath)
                            if ordered_fcts_map(mpath) == -1 || key == -1
                                ordered_fcts_map(mpath) = -1;
                            else
                                ordered_fcts_map(mpath) = ...
                                    max(ordered_fcts_map(mpath), key);
                            end
                        else
                            ordered_fcts_map(mpath) = key;
                        end
                    end
                end
            end
        end
    end
end