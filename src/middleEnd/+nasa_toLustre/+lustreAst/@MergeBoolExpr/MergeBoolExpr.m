%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef MergeBoolExpr < nasa_toLustre.lustreAst.MergeExpr
    %MergeBoolExpr

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
        function new_obj = simplify(obj)            
            new_obj = nasa_toLustre.lustreAst.MergeBoolExpr(...
                obj.clock.simplify(), ...
                obj.true_expr.simplify(), ...
                obj.addWhentrue, ...
                obj.false_expr.simplify(), ...
                obj.addWhenfalse);
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

