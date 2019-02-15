function IfExp = getIfExp(obj, blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    CaseConditions = eval(blk.CaseConditions);
    IfExp = cell(1, numel(CaseConditions));
    for i=1:numel(CaseConditions)
        if numel(CaseConditions{i}) == 1
            IfExp{i} = sprintf('u1 == %d', CaseConditions{i});
        else
            exp = cell(1, numel(CaseConditions{i}));
            for j=1:numel(CaseConditions{i})
                exp{j} = sprintf('u1 == %d', CaseConditions{i}(j));
            end
            IfExp{i} = MatlabUtils.strjoin(exp, ' | ');
        end

    end
    if strcmp(blk.ShowDefaultCase, 'on')
        IfExp{end+1} = '';
    end
end
