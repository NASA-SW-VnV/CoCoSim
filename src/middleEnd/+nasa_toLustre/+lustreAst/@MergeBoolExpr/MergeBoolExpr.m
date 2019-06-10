classdef MergeBoolExpr < nasa_toLustre.lustreAst.MergeExpr
    %MergeBoolExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        true_expr;
        addWhentrue;
        false_expr;
        addWhenfalse;
    end
    
    methods
        function obj = MergeBoolExpr(clock, true_expr, addWhentrue, false_expr, addWhenfalse)
            exprs{1} = true_expr;
            exprs{2} = false_expr;
            obj = obj@nasa_toLustre.lustreAst.MergeExpr(clock, exprs);
            obj.true_expr = true_expr;
            obj.false_expr = false_expr;
            obj.addWhentrue = addWhentrue;
            obj.addWhenfalse = addWhenfalse;
        end
        
        %%
        function code = print(obj, backend)
            if LusBackendType.isKIND2(backend)
                code = obj.print_kind2(backend);
            else
                %TODO: check if LUSTREC syntax is OK for the other backends.
                code = obj.print_lustrec(backend);
            end
        end
        
        function code = print_lustrec(obj, backend)
            clock_str = obj.clock.print(backend);
            true_exp = obj.true_expr.print(backend);
            if obj.addWhentrue
                true_exp = sprintf('%s when %s', ...
                    true_exp, clock_str);
            end
            false_exp = obj.false_expr.print(backend);
            if obj.addWhenfalse
                false_exp = sprintf('%s when false(%s)', ...
                    false_exp, clock_str);
            end
            % lustrec syntax: merge c (true -> e1) (false -> e2);
            code = sprintf('(merge %s \n\t\t(true -> %s) \n\t\t(false -> %s))', ...
                clock_str, true_exp, false_exp);
        end
        
        
        function code = print_kind2(obj, backend)
            clock_str = obj.clock.print(backend);
            true_exp = obj.true_expr.print(backend);
            if obj.addWhentrue
                true_exp = sprintf('%s when %s', ...
                    true_exp, clock_str);
            end
            false_exp = obj.false_expr.print(backend);
            if obj.addWhenfalse
                false_exp = sprintf('%s when not(%s)', ...
                    false_exp, clock_str);
            end
            
            code = sprintf('merge(%s;\n\t\t %s; \n\t\t%s)', ...
                clock_str, true_exp, false_exp);
        end
    end
    
end

