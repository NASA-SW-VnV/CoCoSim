function code = print(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    %TODO: check if LUSTREC syntax is OK for the other backends.
    
    if LusBackendType.isKIND2(backend) ...
            && strcmp(obj.type, 'bool clock')
        dt = 'bool';
    else
        dt = obj.type;
    end
    if LusBackendType.isPRELUDE(backend) ...
            && ~isempty(obj.rate)
        code = sprintf('%s : %s %s;', obj.id, dt, obj.rate);
    else
        code = sprintf('%s : %s;', obj.id, dt);
    end
end
