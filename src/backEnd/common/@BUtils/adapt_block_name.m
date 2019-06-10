function new_name = adapt_block_name(var_name, ID)
    %     new_name = regexprep(var_name,'^__(\w)','$1');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    var_name = matlab.lang.makeValidName(char(var_name));
    prefix = '';
    if nargin >= 2 && ~isempty(ID)
        ID = char(ID);
        %                 display(ID)
        prefix = strcat(ID, '_');
    end
    if numel(prefix)>30
        prefix = strcat('a_', prefix(numel(prefix) - 20 : end));
    end
    if numel(var_name) > 40
        new_name = strcat(prefix,'a_', var_name(numel(var_name) - 30 : end));
    else
        new_name = strcat(prefix, var_name);
    end
    if numel(char(new_name)) > 43
        new_name = BUtils.adapt_block_name(new_name);
    end
    new_name = char(new_name);
end

