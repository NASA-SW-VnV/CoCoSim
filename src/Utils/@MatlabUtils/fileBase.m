
% for fileNames such as "test.LUSTREC.lus" it should returns "test"
function fname = fileBase(path)
    [~, fname, ~ ] = fileparts(path);
    if MatlabUtils.contains(fname, '.')
        [~, fname, ~ ] = MatlabUtils.fileBase(fname);
    end
end
