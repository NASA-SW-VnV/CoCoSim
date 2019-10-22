function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isempty(obj.text)
        return;
    end
    if LusBackendType.isPRELUDE(backend)
        code = sprintf('--%s\n',...
            strrep(obj.text, newline, '--'));
    else
        if obj.isMultiLine
            code = sprintf('(*\n%s\n*)\n', ...
                obj.text);
        else
            code = sprintf('--%s', ...
                obj.text);
        end
    end
end
