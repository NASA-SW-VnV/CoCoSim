%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [node_struct,...
        status] = extract_node_struct_using_lusFile(lus_file_path, node_name)
    status = 0;
    node_struct = [];
    node_struct.inputs = [];
    node_struct.outputs = [];
    lus_text = fileread(lus_file_path);
    
    vars = '(\s*\w+\s*(,\s*\w+\s*)*:\s*(int|real|bool|bool\s+clock)\s*;?(\s*\n*)*)+';
    pattern = strcat(...
        '(node|function)(\s*\n*)+',...
        node_name,...
        '(\s*\n*)*\(',...
        vars,...
        '\)(\s*\n*)*returns(\s*\n*)*\(',...
        vars,'\)\s*;?');
    tokens = regexp(lus_text, pattern,'match');
    if isempty(tokens)
        status = 1;
        display_msg(sprintf('Could not extract node %s information for file %s\n', ...
            node_name, lus_file_path),...
            MsgType.ERROR, 'extract_node_struct_using_lusFile', '');
        return;
    end
    tokens = regexp(tokens{1}, vars,'match');
    if length(tokens) ~= 2
        status = 1;
        display_msg(sprintf('Could not extract node %s information for file %s\n', ...
            node_name, lus_file_path),...
            MsgType.ERROR, 'extract_node_struct_using_lusFile', '');
        return;
    end
    inputs = regexp(tokens{1}, ';', 'split');
    outputs = regexp(tokens{2}, ';', 'split');
    
    for i=1:length(inputs)
        [vars, status] = getVars(inputs{i});
        if status
            display_msg(sprintf('Could not extract node %s information for file %s\n', ...
                node_name, lus_file_path),...
                MsgType.ERROR, 'extract_node_struct_using_lusFile', '');
            return;
        end
        for j=1:length(vars)
            node_struct.inputs(end+1).name = vars{j}.name;
            node_struct.inputs(end).datatype = vars{j}.datatype;
        end
    end
    for i=1:numel(outputs)
        [vars, status] = getVars(outputs{i});
        if status
            display_msg(sprintf('Could not extract node %s information for file %s\n', ...
                node_name, lus_file_path),...
                MsgType.ERROR, 'extract_node_struct_using_lusFile', '');
            return;
        end
        for j=1:length(vars)
            node_struct.outputs(end+1).name = vars{j}.name;
            node_struct.outputs(end).datatype = vars{j}.datatype;
        end
    end
end

function [vars, status] = getVars(token)
    vars = {};
    status = 0;
    if isempty(token)
        return;
    end
    tokens = regexp(token, ':','split');
    
    if length(tokens)~=2
        status = 1;
        return;
    end
    dt_tokens = regexp(tokens{2}, '\w+','match');
    dt = dt_tokens{1}; % bool clock => bool; int => int ...
    names_tokens = regexp(tokens{1}, ',','split');
    for i=1:numel(names_tokens)
        token = regexp(names_tokens{i}, '\w+','match');
        if isempty(token)
            continue;
        else
            vars{end+1} = struct('name', token{1}, 'datatype', dt);
        end
    end
end