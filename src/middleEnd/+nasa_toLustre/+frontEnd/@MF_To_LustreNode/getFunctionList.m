function [new_function_list, failed] = getFunctionList(blk, script)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    em2json =  cocosim.matlab2IR.EM2JSON;
    IR_string = em2json.StringToIR(script);
    IR = json_decode(char(IR_string));
    failed = false;
    if isstruct(IR) && isfield(IR, 'functions')
        functions = IR.functions;
    else
        display_msg(sprintf('Parser failed for Matlab function in block %s', ...
                HtmlItem.addOpenCmd(blk.Origin_path)),...
                MsgType.WARNING, 'getMFunctionCode', '');
        failed = 1;
        return;
    end
    % We do not support nested functions
    new_function_list = {};
    for i=1:length(functions)
        if ~isfield(functions(i), 'statements')
            continue;
        end
        statements = functions(i).statements;
        if isstruct(statements)
            types = arrayfun(@(x) x.type, statements, 'UniformOutput', 0);
            %remove functions from statements
            functions(i).statements(strcmp(types, 'function')) = [];
            new_function_list{end+1} = functions(i);
            new_funcs = statements(strcmp(types, 'function'));
            new_function_list = MatlabUtils.concat(new_function_list, ...
                arrayfun(@(x) {x}, new_funcs));
        else
            types = cellfun(@(x) x.type, statements, 'UniformOutput', 0);
            %remove functions from statements
            functions(i).statements(strcmp(types, 'function')) = [];
            new_function_list{end+1} = functions(i);
            new_funcs = statements(strcmp(types, 'function'));
            new_function_list = MatlabUtils.concat(new_function_list, new_funcs);
        end
        
    end
end