%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [answer, CEX_XML] = extract_answer(...
        solver_output,solver, ...
        file_name, ...
        node_name, ...
        output_dir)
    answer = '';
    CEX_XML = [];
    if isempty(solver_output)
        return
    end
    tmp_file = fullfile(...
        output_dir, ...
        strcat(file_name, '_', node_name, '.xml'));
    fid = fopen(tmp_file, 'w');
    if fid == -1
        display_msg(['Couldn''t create file ' tmp_file],...
            MsgType.ERROR, 'LustrecUtils.extract_answer', '');
        return;
    end
    fprintf(fid, solver_output);
    fclose(fid);
    xDoc = xmlread(tmp_file);
    xProperties = xDoc.getElementsByTagName('Property');
    property = xProperties.item(0);
    try
        answer = ...
            property.getElementsByTagName('Answer').item(0).getTextContent;
    catch
        answer = 'ERROR';
    end

    if strcmp(solver, 'KIND2') || strcmp(solver, 'JKIND') ...
            || strcmp(solver, 'K') || strcmp(solver, 'J')
        if strcmp(answer, 'valid')
            answer = 'SAFE';
        elseif strcmp(answer, 'falsifiable')
            answer = 'CEX';
        end
    end
    if strcmp(answer, 'CEX')
        answer = 'UNSAFE';
    end
    if strcmp(answer, 'UNSAFE')
        if strcmp(solver, 'JKIND') || strcmp(solver, 'J')
            xml_cex = xDoc.getElementsByTagName('Counterexample');
        else
            xml_cex = xDoc.getElementsByTagName('CounterExample');
        end
        if xml_cex.getLength > 0
            CEX_XML = xml_cex;
        else
            msg = sprintf('Could not parse counter example from %s', ...
                solver_output);
            display_msg(msg, MsgType.ERROR, 'Property Checking', '');
        end
    end
    msg = sprintf('Solver Result for file %s of property %s is %s', ...
        file_name, node_name, answer);
    display_msg(msg, MsgType.INFO, 'LustrecUtils.extract_answer', '');
end

