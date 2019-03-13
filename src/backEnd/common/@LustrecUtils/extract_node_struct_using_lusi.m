%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function [node_struct,...
        status] = extract_node_struct_using_lusi(lus_file_path,...
        node_name,...
        LUSTREC)
    [lusi_path, status] = ...
        LustrecUtils.generate_lusi(lus_file_path, LUSTREC );
    if status
        display_msg(sprintf('Could not extract node %s information for file %s\n', ...
            node_name, lus_file_path), MsgType.Error, 'extract_node_struct', '');
        return;
    end
    lusi_text = fileread(lusi_path);
    vars = '(\s*\w+\s*:\s*(int|real|bool);?)+';
    pattern = strcat(...
        '(node|function)\s+',...
        node_name,...
        '\s*\(',...
        vars,...
        '\)\s*returns\s*\(',...
        vars,'\);');
    tokens = regexp(lusi_text, pattern,'match');
    if isempty(tokens)
        status = 1;
        display_msg(sprintf('Could not extract node %s information for file %s\n', ...
            node_name, lus_file_path),...
            MsgType.ERROR, 'extract_node_struct', '');
        return;
    end
    tokens = regexp(tokens{1}, vars,'match');
    inputs = regexp(tokens{1}, ';', 'split');
    outputs = regexp(tokens{2}, ';', 'split');

    for i=1:numel(inputs)
        tokens = regexp(inputs{i}, '\w+','match');
        node_struct.inputs(i).name = tokens{1};
        node_struct.inputs(i).datatype = tokens{2};
    end
    for i=1:numel(outputs)
        tokens = regexp(outputs{i}, '\w+','match');
        node_struct.outputs(i).name = tokens{1};
        node_struct.outputs(i).datatype = tokens{2};
    end
end

