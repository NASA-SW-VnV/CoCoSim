
function mkdir(path)
    tokens = regexp(path, filesep, 'split');
    for i=2:numel(tokens)
        d = MatlabUtils.strjoin(tokens(1:i), filesep);
        if ~exist(d, 'dir')
            mkdir(d);
        end
    end
end
