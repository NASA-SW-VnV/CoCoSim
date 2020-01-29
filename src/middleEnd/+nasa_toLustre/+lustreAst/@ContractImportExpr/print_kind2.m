function code = print_kind2(obj, backend)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    inputs_str = nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.inputs, backend);
    outputs_str = nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.outputs, backend);
    code = sprintf('import %s(%s) returns (%s);', ...
        obj.name, inputs_str, outputs_str );
end
