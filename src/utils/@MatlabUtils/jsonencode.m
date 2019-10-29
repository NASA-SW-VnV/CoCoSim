function json = jsonencode(s)
%JSONENCODE Summary of this function goes here
%   Detailed explanation goes here
    try
        json = jsonencode(s);
    catch
        % buit-in function jsonencode is not supported for versions 2016b
        % and earlier
        % we will use the c function json_encode
        json = json_encode(s);
    end
end

