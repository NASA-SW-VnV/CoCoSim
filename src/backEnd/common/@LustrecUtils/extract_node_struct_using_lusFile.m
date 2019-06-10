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
    lus_text = fileread(lus_file_path);
    
    vars = '(\s*\w+\s*:\s*(int|real|bool)\s*;?(\s*\n*)*)+';
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
    inputs = regexp(tokens{1}, ';', 'split');
    outputs = regexp(tokens{2}, ';', 'split');
    
    for i=1:numel(inputs)
        tokens = regexp(inputs{i}, '\w+','match');
        if isempty(tokens)
            continue;
        elseif length(tokens) == 2
            node_struct.inputs(i).name = tokens{1};
            node_struct.inputs(i).datatype = tokens{2};
        else
            status = 1;
            return;
        end
    end
    for i=1:numel(outputs)
        tokens = regexp(outputs{i}, '\w+','match');
        if isempty(tokens)
            continue;
        elseif length(tokens) == 2
            node_struct.outputs(i).name = tokens{1};
            node_struct.outputs(i).datatype = tokens{2};
        else
            status = 1;
            return;
        end
    end
end

