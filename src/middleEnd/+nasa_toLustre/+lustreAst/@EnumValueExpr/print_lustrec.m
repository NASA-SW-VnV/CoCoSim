function code = print_lustrec(obj, ~)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    % it should start with upper case
    if numel(obj.enum_name) > 1
        code = sprintf('%s%s', upper(obj.enum_name(1)), obj.enum_name(2:end));
    else
        code = upper(obj.enum_name);
    end
end
