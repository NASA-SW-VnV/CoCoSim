function ordered_fcts_map = extract_fcts(ordered_fcts_map, map, lowest_priority)
    for i=1:numel(map)
        [library_path, fname,ext] = fileparts(map{i});
        if MatlabUtils.contains(fname, '*')
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
        
