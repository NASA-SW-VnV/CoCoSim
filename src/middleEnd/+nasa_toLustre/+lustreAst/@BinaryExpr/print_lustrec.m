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
function code = print_lustrec(obj, backend)
    
    global ADD_KIND2_TIMES_ABSTRACTION ADD_KIND2_DIVIDE_ABSTRACTION;
    
    if obj.addEpsilon ...
            && (strcmp(obj.op, '>=') || strcmp(obj.op, '>') ...
            || strcmp(obj.op, '<=') || strcmp(obj.op, '<') ...
            || strcmp(obj.op, '='))
        if strcmp(obj.op, '>=') || strcmp(obj.op, '<=') ...
                || strcmp(obj.op, '=')
            epsilonOp = nasa_toLustre.lustreAst.BinaryExpr.LTE;
            and_or = 'or';
        else
            epsilonOp = nasa_toLustre.lustreAst.BinaryExpr.GT;
            and_or = 'and';
        end
        if isempty(obj.epsilon)
            if isa(obj.left, 'nasa_toLustre.lustreAst.RealExpr')
                obj.epsilon = eps(obj.left.getValue());
            elseif isa(obj.right, 'nasa_toLustre.lustreAst.RealExpr')
                obj.epsilon = eps(obj.right.getValue());
            else
                obj.epsilon = 1e-15;
            end
        end
        code = sprintf('((%s %s %s) %s abs_real(%s - %s) %s %.30f)', ...
            obj.left.print(backend),...
            obj.op, ...
            obj.right.print(backend), ...
            and_or, ...
            obj.left.print(backend),...
            obj.right.print(backend), ...
            epsilonOp, ...
            obj.epsilon);
    else
        if strcmp(obj.operandsDT, 'real') ...
                && strcmp(obj.op, nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY) ...
                && LusBackendType.isKIND2(backend)
            
            ADD_KIND2_TIMES_ABSTRACTION = true;
            code = sprintf('kind2_times(%s, %s)', ...
                obj.left.print(backend),...
                obj.right.print(backend));
        elseif strcmp(obj.operandsDT, 'real') ...
                && strcmp(obj.op, nasa_toLustre.lustreAst.BinaryExpr.DIVIDE) ...
                && LusBackendType.isKIND2(backend)
            
            ADD_KIND2_DIVIDE_ABSTRACTION = true;
            code = sprintf('kind2_divide(%s, %s)', ...
                obj.left.print(backend),...
                obj.right.print(backend));
        else
            left = obj.left.print(backend);
            if strcmp(obj.op, nasa_toLustre.lustreAst.BinaryExpr.ARROW) ...
                    || ( isa(obj.left, 'nasa_toLustre.lustreAst.BinaryExpr') ...
                    && ~obj.left.withPar ...
                    && (strcmp(obj.op, '*') || strcmp(obj.op, '/') || strcmp(obj.op, 'Div')))
                left = sprintf('(%s)', left);
            end
            right = obj.right.print(backend);
            if strcmp(obj.op, nasa_toLustre.lustreAst.BinaryExpr.ARROW) ...
                    || ...
                    ( isa(obj.right, 'nasa_toLustre.lustreAst.BinaryExpr')...
                    && ~obj.right.withPar ...
                    && (strcmp(obj.op, '*') || strcmp(obj.op, '/') || strcmp(obj.op, 'Div')))
                right = sprintf('(%s)', right);
            end
            code = sprintf('%s %s %s', left, obj.op, right);
            if obj.withPar
                code = sprintf('(%s)', code);
            end
        end
        
    end
end
