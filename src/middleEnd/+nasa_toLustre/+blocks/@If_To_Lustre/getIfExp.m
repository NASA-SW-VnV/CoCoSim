function IfExp = getIfExp(blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    IfExp{1} =  blk.IfExpression;
    elseExp = split(blk.ElseIfExpressions, ',');
    IfExp = [IfExp; elseExp];
    if strcmp(blk.ShowElse, 'on')
        IfExp{end+1} = '';
    end
end
