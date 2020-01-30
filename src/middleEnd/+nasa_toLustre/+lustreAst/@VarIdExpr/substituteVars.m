function new_obj = substituteVars(obj, var, newVar)

    if strcmp(obj.getId(), var.getId())
        new_obj = newVar;
    else
        new_obj = obj;
    end
end
