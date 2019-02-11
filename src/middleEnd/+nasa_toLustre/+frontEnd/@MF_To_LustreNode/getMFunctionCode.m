function [body, failed] = getMFunctionCode(parent,  blk, MF_DATA_MAP)
    %GETMFUNCTIONCODE
    failed = false;
    body = {};
    % get all user functions needed in one script
    [script, failed] = addrequiredFunctions(blk );
    if failed
        return;
    end
    em2json =  cocosim.matlab2IR.EM2JSON;
    IR_string = em2json.StringToIR(script);
    IR = json_decode(char(IR_string));
    func_names = {};
    if isstruct(IR) && isfield(IR, 'functions')
        functions = IR.functions;
        for i=1:length(functions)
            func_names{end+1} = functions(1).name;
            statements = functions(1).statements;
            for j=1:length(statements)
                if isstruct(statements(j))
                    s = statements(j);
                elseif iscell(statements(j))
                    s = statements{j};
                else
                    continue;
                end
                if isstruct(s) && isfield(s, 'type') ...
                        && isequal(s.type, 'function')
                    func_names{end+1} = s.name;
                end
            end
        end
    end
    if numel(func_names) > 1
        msg = '';
        display_msg(sprintf(['Matlab Function in block "%s" calls user-defined functions: "%s".\n'...
            'Currently this compiler supports only one Matlab file and one function per file.'], ...
            HtmlItem.addOpenCmd(blk.Origin_path), MatlabUtils.strjoin(func_names, ', ')), ...
            MsgType.DEBUG, 'getMFunctionCode', '');
        
        failed = true;
        return;
    end
    
end

function [script, failed] = addrequiredFunctions(blk)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    failed = false;
    script = blk.Script;
    blk_name = SLX2LusUtils.node_name_format(blk);
    func_path = fullfile(pwd, strcat(blk_name, '.m'));
    fid = fopen(func_path, 'w');
    if fid < 0
        display_msg(sprintf('Could not open file "%s" for writing', func_path), ...
            MsgType.DEBUG, 'getMFunctionCode', '');
        failed = true;
        return;
    end
    fprintf(fid, script);
    fclose(fid);
    fList = matlab.codetools.requiredFilesAndProducts(func_path);
    if numel(fList) > 1
        for i=2:length(fList)
            script = sprintf('%s\n%s', script, fileread(fList{i}));
        end
    end
    
end