function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    if LusBackendType.isKIND2(backend) ...
            && isequal(obj.type, 'bool clock')
        dt = 'bool';
    else
        dt = obj.type;
    end
    
    code = sprintf('%s : %s;', obj.name, dt);
end
