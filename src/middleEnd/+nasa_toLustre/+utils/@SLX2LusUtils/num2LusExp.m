
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% change numerical value to Lustre Expr string based on DataType dt.
function lustreExp = num2LusExp(v, lus_dt, slx_dt)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    global TOLUSTRE_ENUMS_MAP;
    if nargin < 3
        slx_dt = lus_dt;
    end
    if isKey(TOLUSTRE_ENUMS_MAP, lus_dt)
        lustreExp = EnumValueExpr(char(v));
    elseif strcmp(lus_dt, 'real')
        lustreExp = RealExpr(v);
    elseif strcmp(lus_dt, 'int')
        if numel(slx_dt) > 3 ...
                && strncmp(slx_dt, 'int', 3) ...
                || strncmp(slx_dt, 'uint', 4)
            % e.g. cast double value to int32
            f = eval(strcat('@', slx_dt));
            lustreExp = IntExpr(...
                f(v));
        else
            lustreExp = IntExpr(v);
        end
    elseif strcmp(lus_dt, 'bool')
        lustreExp = BooleanExpr(v);
    elseif strncmp(slx_dt, 'int', 3) ...
            || strncmp(slx_dt, 'uint', 4)
        lustreExp = IntExpr(v);
    elseif strcmp(slx_dt, 'boolean') || strcmp(slx_dt, 'logical')
       lustreExp = BooleanExpr(v);
    else
        lustreExp = RealExpr(v);
    end
end
