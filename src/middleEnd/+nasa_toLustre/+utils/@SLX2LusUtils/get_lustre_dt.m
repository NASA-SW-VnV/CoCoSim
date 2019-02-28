
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Change Simulink DataTypes to Lustre DataTypes. Initial default
%value is also given as a string.
function [ Lustre_type, zero, one, isBus, isEnum, hasEnum] = ...
        get_lustre_dt( slx_dt)
    %L = nasa_toLustre.ToLustreImport.L;% Avoiding importing functions. Use direct indexing instead for safe call
    %import(L{:})
    global TOLUSTRE_ENUMS_MAP;
    if isempty(TOLUSTRE_ENUMS_MAP)
        TOLUSTRE_ENUMS_MAP = containers.Map;
    end
    isBus = false;
    isEnum = false;
    hasEnum = false;
    if strcmp(slx_dt, 'real') || strcmp(slx_dt, 'int') || strcmp(slx_dt, 'bool')
        Lustre_type = slx_dt;
    else
        if strcmp(slx_dt, 'logical') || strcmp(slx_dt, 'boolean') ...
                || strcmp(slx_dt, 'action') || strcmp(slx_dt, 'fcn_call')
            Lustre_type = 'bool';
        elseif strncmp(slx_dt, 'int', 3) || strncmp(slx_dt, 'uint', 4) || strncmp(slx_dt, 'fixdt(1,16,', 11) || strncmp(slx_dt, 'sfix64', 6)
            Lustre_type = 'int';
        elseif strcmp(slx_dt, 'double') || strcmp(slx_dt, 'single')
            Lustre_type = 'real';
        else
            % considering enumaration as int
            if strncmp(slx_dt, 'Enum:', 4)
                slx_dt = regexprep(slx_dt, 'Enum:\s*', '');
            end
            if isKey(TOLUSTRE_ENUMS_MAP, lower(slx_dt))
                isEnum = true;
                hasEnum = true;
                Lustre_type = lower(slx_dt);
            else 
                isBus = SLXUtils.isSimulinkBus(char(slx_dt));
                if isBus
                    Lustre_type = nasa_toLustre.utils.SLX2LusUtils.getLustreTypesFromBusObject(char(slx_dt));
                else
                    Lustre_type = 'real';
                end
            end

        end
    end
    if iscell(Lustre_type)
        zero = {};
        one = {};
        for i=1:numel(Lustre_type)
            if isKey(TOLUSTRE_ENUMS_MAP, Lustre_type{i})
                members = TOLUSTRE_ENUMS_MAP(Lustre_type{i});
                % DefaultValue of Enum is the first element
                zero{i} = members{1};
                one{i} = members{1};
                hasEnum = true;
            elseif strcmp(Lustre_type{i}, 'bool')
                zero{i} = nasa_toLustre.lustreAst.BooleanExpr('false');
                one{i} = nasa_toLustre.lustreAst.BooleanExpr('true') ;
            elseif strcmp(Lustre_type{i}, 'int')
                zero{i} = nasa_toLustre.lustreAst.IntExpr('0');
                one{i} = nasa_toLustre.lustreAst.IntExpr('1');
            else
                zero{i} = nasa_toLustre.lustreAst.RealExpr('0.0');
                one{i} = nasa_toLustre.lustreAst.RealExpr('1.0');
            end
        end
    else
        if isKey(TOLUSTRE_ENUMS_MAP, Lustre_type)
            members = TOLUSTRE_ENUMS_MAP(Lustre_type);
            zero = members{1};
            one = members{1};
            hasEnum = true;
        elseif strcmp(Lustre_type, 'bool')
            zero = nasa_toLustre.lustreAst.BooleanExpr('false');
            one = nasa_toLustre.lustreAst.BooleanExpr('true');
        elseif strcmp(Lustre_type, 'int')
            zero = nasa_toLustre.lustreAst.IntExpr('0');
            one = nasa_toLustre.lustreAst.IntExpr('1');
        else
            zero = nasa_toLustre.lustreAst.RealExpr('0.0');
            one = nasa_toLustre.lustreAst.RealExpr('1.0');
        end
    end
end

