function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    new_obj = obj.deepCopy();
    if ~isempty(outputs_map) && isKey(outputs_map, obj.getId())
        occ = outputs_map(obj.getId());
        if isLeft
            %increase number of occurance
            occ = occ + 1;
        end
        if occ == 0
            %first time appeared on the right. set default value
            if ~nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(obj, node.getInputs()) ...
                    && data_map.isKey(obj.getId())
                d = data_map(obj.getId());
                if isstruct(d)
                    if isfield(d, 'InitialValue')
                        init = d.InitialValue;
                    else
                        init = 0;
                    end
                    if isfield(d, 'LusDatatype')
                        dt = d.LusDatatype;
                    else
                        dt = 'real';
                    end
                else
                    init = 0;
                    dt = d;
                end
                if strcmp(dt, 'int')
                    new_obj = nasa_toLustre.lustreAst.IntExpr(init);
                elseif strcmp(dt, 'bool')
                    new_obj = nasa_toLustre.lustreAst.BoolExpr(init);
                else
                    new_obj = nasa_toLustre.lustreAst.RealExpr(init);
                end
            end
        else
            new_obj.setId(strcat(obj.getId(), '__', num2str(occ)));
        end
        outputs_map(obj.getId()) = occ;
    end
end
