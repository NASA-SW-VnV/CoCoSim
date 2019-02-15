function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    exprs_cell = cellfun(@(x) sprintf('(%s)', x.print(backend)),...
        obj.exprs, 'UniformOutput', 0);
    exprs_str = MatlabUtils.strjoin(exprs_cell, '\n\t\t');
    
    code = sprintf('(merge %s\n\t\t %s)', obj.clock.print(backend), exprs_str);
end
