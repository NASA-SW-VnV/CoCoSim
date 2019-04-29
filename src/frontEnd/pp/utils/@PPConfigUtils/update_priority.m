function ordered_fcts_map = update_priority(ordered_fcts_map, pp_order_map)
    for key= sort(cell2mat(pp_order_map.keys))
        v_list = pp_order_map(key);
        for i=1:numel(v_list)
            [library_path, fname,ext] = fileparts(v_list{i});
            if MatlabUtils.contains(fname, '*')
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
