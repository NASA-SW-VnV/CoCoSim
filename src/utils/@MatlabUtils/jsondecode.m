function json = jsondecode(s)
%JSONENCODE Summary of this function goes here
%   Detailed explanation goes here
    try
        json = jsondecode(s);
    catch
        % buit-in function jsondecode is not supported for versions 2016b
        % and earlier
        % we will use the c function json_encode
        json = jsondecode(s);
    end
end

