
function status = add_funLibrary_path(dst_path, fun_name, fun_library, position)
    status = 0;
    if strcmp(fun_library, 'lustrec_math') || strcmp(fun_library, 'math')
        function_name = fun_name;
        fcn_path = 'simulink/Math Operations/Trigonometric Function';
        needFunctionParam = true;
        if strcmp(fun_name, 'cbrt')
        elseif strcmp(fun_name, 'ceil')
            fcn_path = 'simulink/Math Operations/Rounding Function';
        elseif strcmp(fun_name, 'fabs')
            needFunctionParam = false;
            fcn_path = 'simulink/Math Operations/Abs';
        elseif strcmp(fun_name, 'pow')
            fcn_path = 'simulink/Math Operations/Math Function';
        elseif strcmp(fun_name, 'sqrt')
            needFunctionParam = false;
            fcn_path = 'simulink/Math Operations/Sqrt';
        end
        if needFunctionParam
            add_block(fcn_path,...
                dst_path,...
                'Function', function_name,...
                'Position',position);
        else
            add_block(fcn_path,...
                dst_path,...
                'Position',position);
        end
    elseif strcmp(fun_library, 'conv')
        fcn_path = 'simulink/Signal Attributes/Data Type Conversion';
        dt = 'double';
        if strcmp(fun_name, 'real_to_int')
            dt = 'int32';
        end
        add_block(fcn_path,...
            dst_path,...
            'OutDataTypeStr', dt,...
            'Position',position);

    else
        status = 1;
    end
end
