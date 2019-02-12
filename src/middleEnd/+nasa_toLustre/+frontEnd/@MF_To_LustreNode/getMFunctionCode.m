function [body, external_libraries, failed] = getMFunctionCode(parent,  blk, Inputs, Outputs)
    %GETMFUNCTIONCODE
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    body = {};
    external_libraries = {};
    % get all user functions needed in one script
    [script, failed] = addrequiredFunctions(blk );
    if failed, return; end
    em2json =  cocosim.matlab2IR.EM2JSON;
    IR_string = em2json.StringToIR(script);
    IR = json_decode(char(IR_string));
    
    if isstruct(IR) && isfield(IR, 'functions')
        functions = IR.functions;
        func_names = getFuncsNames(functions);
    else
        display_msg(sprintf('Parser failed for Matlab function in block %s', ...
                blk.Origin_path),...
                MsgType.WARNING, 'getMFunctionCode', '');
        failed = 1;
        return;
    end
    if isempty(func_names)
        display_msg(sprintf('Parser failed for Matlab function in block %s. No function has been found.', ...
                blk.Origin_path),...
                MsgType.WARNING, 'getMFunctionCode', '');
        failed = 1;
        return;
    elseif numel(func_names) > 1
        %TODO: Work on progress to support more than one function definition.
        display_msg(sprintf(['Matlab Function in block "%s" calls user-defined functions: "%s".\n'...
            'Currently this compiler supports only one Matlab file and one function per file.'...
            ' This block will be abstracted.'], ...
            HtmlItem.addOpenCmd(blk.Origin_path), MatlabUtils.strjoin(func_names, ', ')), ...
            MsgType.WARNING, 'getMFunctionCode', '');
        failed = true;
        return;
    end
    % creat DATA_MAP
    [data_map, failed] = getFunVars(blk, script, ...
        func_names{1}, functions(1).has_END, Inputs, Outputs);
    if failed, return; end
    statements = functions(1).statements;
    expected_dt = '';
    isSimulink = false;
    isStateFlow = false;
    isMatlabFun = true;
    BlkObj = DummyBlock_To_Lustre();
    for i=1:length(statements)
        if isstruct(statements)
            s = statements(i);
        else
            s = statements{i};
        end
        try
            lusCode = MExpToLusAST.expression_To_Lustre(BlkObj, s,...
                parent, blk, data_map, {}, expected_dt, isSimulink, isStateFlow, isMatlabFun);
            body = MatlabUtils.concat(body, lusCode);
        catch me
            if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                display_msg(me.message, MsgType.WARNING, 'getMFunctionCode', '');
            else
                display_msg(me.getReport(), MsgType.DEBUG, 'getMFunctionCode', '');
            end
            display_msg(sprintf('Statement "%s" failed for block %s', ...
                s.text, blk.Origin_path),...
                MsgType.WARNING, 'getMFunctionCode', '');
        end
    end
    external_libraries = BlkObj.getExternalLibraries();
end
%% copy all required functions in one script
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
    try delete(func_path), catch, end
end
%% get Function names
function func_names = getFuncsNames(functions)
    func_names = arrayfun(@(x) x.name, functions, 'UniformOutput', 0);
    for i=1:length(functions)
        statements = functions(i).statements;
        if isstruct(statements)
            types = arrayfun(@(x) x.type, statements, 'UniformOutput', 0);
            funcs = statements(strcmp(types, 'function'));
            names = arrayfun(@(x) x.name, funcs, 'UniformOutput', 0);
        else
            types = cellfun(@(x) x.type, statements, 'UniformOutput', 0);
            funcs = statements(strcmp(types, 'function'));
            names = cellfun(@(x) x.name, funcs, 'UniformOutput', 0);
        end
        func_names = MatlabUtils.concat(func_names, names);
    end
end
%% run the function for random inputs and get function workspace
function [data_map, failed] = getFunVars(blk, script, ...
        func_name,  has_END, Inputs, Outputs)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    data_map = containers.Map;
    failed = false;
    
    % create matlab file to execute it and get all its workspace
    blk_name = SLX2LusUtils.node_name_format(blk);
    func_path = fullfile(pwd, strcat(blk_name, '.m'));
    fid = fopen(func_path, 'w');
    if fid < 0
        display_msg(sprintf('Could not open file "%s" for writing', func_path), ...
            MsgType.DEBUG, 'getMFunctionCode', '');
        failed = true;
        return;
    end
    fun_header = sprintf('function f = %s()\n\tf = @%s; \n\tCoCoVars = [];', ...
        blk_name, func_name);
    fprintf(fid, fun_header);
    fprintf(fid, '\n');
    script = regexprep(script, '%', '%%');
    if has_END
        script = regexprep(script, 'end[.]*$', 'CoCoVars = whos;\nend\nend');
        fprintf(fid, script);
    else
        fprintf(fid, script);
        fprintf(fid, 'CoCoVars = whos;\nend\nend');
    end
    fclose(fid);
    fH = evalin('base', sprintf('%s()', blk_name));
    % create function inputs
    min = 1;max = 10;
    args = cellfun(@(x) ...
        SLXUtils.get_random_values( 1, min, max, ...
        str2num(x.CompiledSize), x.CompiledType{1}), Inputs, 'UniformOutput', 0);
    %call function
    try
        fH(args{:});
    catch me
        display_msg(me.getReport(), ...
            MsgType.DEBUG, 'getMFunctionCode', '');
        failed = true;
        try delete(func_path), catch, end
        return;
    end
    fhinfo = functions(fH);
    if isfield(fhinfo, 'workspace') && isfield(fhinfo.workspace{1}, 'CoCoVars')
        CoCoVars = fhinfo.workspace{1}.CoCoVars;
        inputs_names = cellfun(@(x) x.Name, Inputs, 'UniformOutput', 0);
        outputs_names = cellfun(@(x) x.Name, Outputs, 'UniformOutput', 0);
        for i=1:length(CoCoVars)
            data_map(CoCoVars(i).name) = buildData(CoCoVars(i), inputs_names, ...
                outputs_names);
        end
    else
        display_msg(sprintf('Getting workspace of Matlab function in block %s failed.', ...
                blk.Origin_path),...
                MsgType.WARNING, 'getMFunctionCode', '');
        failed = true;
    end
    try delete(func_path), catch, end
end

function data = buildData(d, inputs_names, outputs_names)
    data = struct();
    CompiledType = d.class;
    data.Name = d.name;
    data.LusDatatype = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( CompiledType);
    data.Datatype = CompiledType;
    data.CompiledType = CompiledType;
    data.InitialValue = '0';
    data.ArraySize = num2str(d.size);
    data.CompiledSize = num2str(d.size);
    if ismember(d.name, inputs_names)
        data.Scope = 'Input';
    elseif ismember(d.name, outputs_names)
        data.Scope = 'Output';
    else
        data.Scope = 'Local';
    end
end