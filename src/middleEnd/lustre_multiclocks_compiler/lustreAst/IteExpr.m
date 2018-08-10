classdef IteExpr < LustreExpr
    %IteExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        condition;
        thenExpr;
        ElseExpr;
        OneLine;% to print it in one line
    end
    
    methods
        function obj = IteExpr(condition, thenExpr, ElseExpr, OneLine)
            obj.condition = condition;
            obj.thenExpr = thenExpr;
            obj.ElseExpr = ElseExpr;
            if exist('OneLine', 'var')
                obj.OneLine = OneLine;
            else
                obj.OneLine = false;
            end
        end
        
        function new_obj = deepCopy(obj)
            new_obj = IteExpr(obj.condition.deepCopy(),...
                obj.thenExpr.deepCopy(),...
                obj.ElseExpr.deepCopy(),...
                obj.OneLine);
        end
        
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        
        function code = print_lustrec(obj, backend)
            if iscell(obj.thenExpr) && numel(obj.thenExpr) == 1
                obj.thenExpr = obj.thenExpr{1};
            end
            if iscell(obj.ElseExpr) && numel(obj.ElseExpr) == 1
                obj.ElseExpr = obj.ElseExpr{1};
            end
            if iscell(obj.condition) && numel(obj.condition) == 1
                obj.condition = obj.condition{1};
            end
            
            if obj.OneLine
                code = sprintf('(if %s then %s else %s)', ...
                    obj.condition.print(backend),...
                    obj.thenExpr.print(backend), ...
                    obj.ElseExpr.print(backend));
            else
                code = sprintf('if %s then\n\t\t%s\n\t    else %s', ...
                    obj.condition.print(backend),...
                    obj.thenExpr.print(backend), ...
                    obj.ElseExpr.print(backend));
            end
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(BackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(BackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(BackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(BackendType.PRELUDE);
        end
    end
    methods(Static)
        % This function return the IteExpr object
        % representing nested if-else.
        function exp = nestedIteExpr(conds, thens)
            if numel(thens) ~= numel(conds) + 1
                display_msg('Number of Thens expressions should be equal to Numbers of Conds + 1',...
                    MsgType.ERROR, 'IteExpr.nestedIteExpr', '');
                exp = VarIdExpr('');
                return;
            end
            if isempty(conds)
                exp = thens;
            elseif numel(conds) == 1
                if iscell(conds)
                    c = conds{1};
                else
                    c = conds;
                end
                exp = IteExpr(c, thens{1}, thens{2});
            else
                exp = IteExpr(conds{1}, ...
                    thens{1}, ...
                    IteExpr.nestedIteExpr( conds(2:end), thens(2:end)) ...
                    );
            end
        end
    end
end

