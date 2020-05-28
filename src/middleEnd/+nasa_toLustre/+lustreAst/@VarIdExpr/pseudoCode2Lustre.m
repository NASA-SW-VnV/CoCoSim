function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
    % The inputs that are not outputs should have a suffix "__0" to avoid
    % inputs/variables with a special name or Lustre keyword: e.g., mode,
    % let, tel...
    
    new_obj = obj.deepCopy();
    if ~isempty(outputs_map) && isKey(outputs_map, obj.getId())
        occ = outputs_map(obj.getId());
        if isLeft
            %increase number of occurance
            occ = occ + 1;
        end
        if occ == 0 ...
                &&  ~nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(obj, node.getInputs())
            %first time appeared on the right. set default value
            if data_map.isKey(obj.getId())
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
    elseif nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(obj, node.getInputs())
        % pure inputs
        new_obj.setId(strcat(obj.getId(), '__0'));
    end
end
