function [lus_code, plu_code] = print_prelude(obj)

    [lus_code, plu_code] = obj.print_lustrec(LusBackendType.PRELUDE);
end
