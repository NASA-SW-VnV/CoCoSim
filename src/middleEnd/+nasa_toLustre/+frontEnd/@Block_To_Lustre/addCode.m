function addCode(obj, code)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    if iscell(code)
        obj.lustre_code = [obj.lustre_code, code];
    elseif ~ischar(code) && numel(code) > 1
        for i=1:numel(code)
            obj.lustre_code{end +1} = code(i);
        end
    else
        obj.lustre_code{end +1} = code;
    end
end
