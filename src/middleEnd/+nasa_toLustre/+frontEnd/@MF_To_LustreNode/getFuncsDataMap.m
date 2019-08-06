function [fun_data_map, failed] = getFuncsDataMap(blk, script, ...
        functions_struct, Inputs)
    %% run the function for random inputs and get function workspace
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %
    %
    fun_data_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
    failed = false;
    %% create matlab file to execute it and get all its workspace
    blk_name = nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    try
        [func_path, failed] = print_script(functions_struct, script);
        if failed, return;end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'MF_To_LustreNode.getFuncsDataMap', '');
        failed = true;
        return;
    end
    %% call function handle
    %fH = evalin('base', sprintf('%s()', blk_name));
    [fun_dir, fun_name, ~] = fileparts(func_path);
    PWD = pwd;
    cd(fun_dir);
    blkFunHandle = str2func(fun_name);
    fH = blkFunHandle();
    % create function inputs
    min = 1;max = 10;
    args = cellfun(@(x) ...
        SLXUtils.get_random_values( 1, min, max, ...
        str2num(x.CompiledSize), x.CompiledType{1}), Inputs, 'UniformOutput', 0);
    %call function
    failed = callFunction(fH, args, func_path, blk);
    if failed
        try delete(func_path), catch, end
        return;
    end
    fhinfo = functions(fH);
    if isfield(fhinfo, 'workspace') && isfield(fhinfo.workspace{1}, 'CoCoVars')
        CoCoVars = fhinfo.workspace{1}.CoCoVars;
        if length(CoCoVars) ~= length(functions_struct)
            display_msg(sprintf('Could not get Information about DataType of variables in block %s.', ...
                HtmlItem.addOpenCmd(blk.Origin_path)), ...
                MsgType.DEBUG, 'getFuncsDataMap', '');
            failed = true;
            return;
        end
        for i=1:length(CoCoVars)
            inputs_names = functions_struct{i}.input_params;
            outputs_names = functions_struct{i}.return_params;
            data = arrayfun(@(d) ...
                buildData(d, inputs_names, outputs_names), CoCoVars{i}, 'UniformOutput', 0);
            data_names = arrayfun(@(d) d.name, CoCoVars{i}, 'UniformOutput', 0);
            data_map = containers.Map(data_names, data);
            data_map = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addArrayData(data_map, data);
            fun_data_map(functions_struct{i}.name) = data_map;
        end
    else
        display_msg(sprintf('Getting workspace of Matlab function in block %s failed.', ...
            HtmlItem.addOpenCmd(blk.Origin_path)),...
            MsgType.WARNING, 'getFuncsDataMap', '');
        failed = true;
    end
    cd (PWD);
    try delete(func_path), catch, end
end
%%
function [func_path, failed] = print_script(funcsList, script)
    func_path = strcat(tempname, '.m');
    [fun_dir, fun_name, ~] = fileparts(func_path);
    fid = fopen(func_path, 'w');
    failed = false;
    if fid < 0
        display_msg(sprintf('Could not open file "%s" for writing', func_path), ...
            MsgType.DEBUG, 'getFuncsDataMap', '');
        failed = true;
        return;
    end
    func_name = funcsList{1}.name;
    fun_header = sprintf('function f = %s()\n\tf = @%s; \n\tCoCoVars = {};', ...
        fun_name, func_name);
    fprintf(fid, fun_header);
    fprintf(fid, '\n');
    %clean up script
    % remove multiline comment
    script = regexprep(script, '%\{(.|[\r\n])*?%\}', '');
    % remove one line comment
    script = regexprep(script, '%[^\r\n]*[\r\n]?', '');
    % remove multi return to line
    script = regexprep(script, '[\r\n]+', '\n');
    
    % for sprintf
    script = regexprep(script, '%', '%%');
    functions_code = regexp(script, '(^|[\s\t\r\n]+)function ', 'split');
    %remove empty match
    functions_code = functions_code(~strcmp(functions_code, ''));
    if length(functions_code) ~= length(funcsList)
        display_msg(sprintf('Number of functions in Script is different from IR.'), ...
            MsgType.DEBUG, 'getFuncsDataMap', '');
        failed = true;
        return;
    end
    for i=1:length(funcsList)
        has_END = funcsList{i}.has_END;
        
        if has_END
            func_code = functions_code{i};
            I = regexp(func_code, '(^|[\s\t\r\n]+)end', 'end');
            idx = I(end);
            if length(func_code) >= idx+1
                
                new_fun_code = sprintf('function %s\nCoCoVars{%d} = whos;\nend\n%s',...
                    func_code(1:idx-3), i, func_code(idx+1:end));
            elseif length(func_code) >= idx
                new_fun_code = sprintf('function %s\nCoCoVars{%d} = whos;\nend\n',...
                    func_code(1:idx-3), i);
            else
                %PAS POSSIBLE
                new_fun_code = sprintf('function %s', func_code);
            end
            functions_code{i} = new_fun_code;
            
            %OLD Method:
            %             end_codes = regexp(functions_code{i}, '(^|[\s\t\r\n]+)end', 'split');
            %             % end_codes = end_codes(~strcmp(end_codes, ''));
            % %             if length(end_codes) == 1
            % %                 functions_code{i} = ...
            % %                     sprintf('function %s\nCoCoVars{%d} = whos;\nend', ...
            % %                     end_codes{1}, i);
            % %             else
            %                 body = MatlabUtils.strjoin(end_codes, '\nend\n');
            %                 functions_code{i} = ...
            %                     sprintf('function %s\nCoCoVars{%d} = whos;\nend\n',...
            %                     body, i);
            % %             end
        else
            functions_code{i} = ...
                sprintf('function %s\nCoCoVars{%d} = whos;\nend', ...
                functions_code{i}, i);
        end
    end
    fprintf(fid, MatlabUtils.strjoin(functions_code, '\n'));
    % the end of the main function under the name blk_name
    fprintf(fid, '\nend');
    fclose(fid);
end
%% call function with random args
function failed = callFunction(fH, args, func_path, blk, loop_flag)
    if nargin < 5 || isempty(loop_flag)
        loop_flag = false;
    end
    failed = false;
    try
        fH(args{:});
    catch me
        
        if strcmp(me.identifier, 'MATLAB:innerdim') && ~loop_flag
            % in Simulink a vector of 3 elements can be considered of dimension
            % [3 1] or [1 3]
            % the following code will try to call the function with all different
            % settings by transposing vectors
            I = (1:length(args));
            II = I(cellfun(@(x) isvector(x) && length(x) > 1, args));
            if length(II) >= 1
                c = arrayfun(@(x) [0 1], (1:length(II)), 'UniformOutput', 0);
                c2 = MatlabUtils.cartesian(c{:});
                [n, ~] = size(c2);
                for i=1:n
                    III = II(boolean(c2(i, :)));
                    if isempty(III)
                        continue;
                    end
                    new_args = args;
                    for j=1:length(III)
                        new_args{III(j)} = new_args{III(j)}';
                    end
                    failed = callFunction(fH, new_args, func_path, blk, true);
                    if ~failed
                        return;
                    end
                end
            end
        end
        display_msg(me.getReport(), ...
            MsgType.DEBUG, 'getFuncsDataMap', '');
        if MatlabUtils.startsWith(me.identifier, 'MATLAB:') ...
                && length(me.stack) >= 1 && isfield(me.stack(1), 'file') ...
                && strcmp(me.stack(1).file, func_path)
            filetext = fileread(me.stack(1).file);
            filecell = regexp(filetext, '\n', 'split');
            if length(filecell) >= me.stack(1).line
                msg = sprintf('Error "%s": in "%s" in block %s\n', ...
                    me.message, filecell{me.stack(1).line}, ...
                    HtmlItem.addOpenCmd(blk.Origin_path));
                display_msg(msg, MsgType.ERROR, 'getFuncsDataMap', '');
            end
        end
        failed = true;
        
        return;
    end
end
%%
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
        data.Port = find(strcmp(data.Name, inputs_names));
    elseif ismember(d.name, outputs_names)
        data.Scope = 'Output';
        data.Port = find(strcmp(data.Name, outputs_names));
    else
        data.Scope = 'Local';
    end
end
