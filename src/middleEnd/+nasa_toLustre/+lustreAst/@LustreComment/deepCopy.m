function new_obj = deepCopy(obj)

    new_obj = nasa_toLustre.lustreAst.LustreComment(obj.text,...
        obj.isMultiLine);
end
