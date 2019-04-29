function path_prefix = getPackagePrefix(f_parent, f_name)
    path_parts = regexp(f_parent, filesep, 'split');
    % keep only package path
    path_partsWithPlusAndAT = path_parts(MatlabUtils.startsWith(path_parts, '+') ...
        |MatlabUtils.startsWith(path_parts, '@'));
    % remove package and class folder prefix
    prefix_parts = regexprep(path_partsWithPlusAndAT, '^(+|@)', '');
    if startsWith(path_partsWithPlusAndAT{end}, '@') ...
            && strcmp(prefix_parts{end}, f_name)
        % case of class folder @ClassName
        path_prefix = MatlabUtils.strjoin(prefix_parts(1:end-1), '.');
    else
        path_prefix = MatlabUtils.strjoin(prefix_parts, '.');
    end
end

