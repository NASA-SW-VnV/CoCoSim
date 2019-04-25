%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [valid, IN_struct] = extract_Kind2_Comp_Verif_answer(...
    lus_full_path, ...
    solver_output, ...
    file_name, ...
    output_dir)
    valid = -1;
    IN_struct = [];
    if isempty(solver_output)
        return
    end
    solver_output = regexprep(solver_output, '<AnalysisStart ([^/]+)/>','<Analysis $1>');
    solver_output = regexprep(solver_output, 'concrete="[^"]+"','');
    solver_output = strrep(solver_output, '<AnalysisStop/>','</Analysis>');
    solver_output = regexprep(solver_output, '<Log class="note" [^/]+/Log>','');
    solver_output = regexprep(solver_output, '<Log class="warn" [^/]+/Log>','');
    solver_output = regexprep(solver_output, '\n\s*\n','\n');

    tmp_file = fullfile(...
        output_dir, ...
        strcat(file_name, '.kind2.xml'));
    i = 1;
    while exist(tmp_file, 'file')
        tmp_file = fullfile(...
            output_dir, ...
            strcat(file_name, '.kind2.', num2str(i), '.xml'));
        i = i +1;
    end
    fid = fopen(tmp_file, 'w');
    if fid == -1
        display_msg(['Couldn''t create file ' tmp_file],...
            MsgType.ERROR, 'Kind2Utils2.extract_answer', '');
        return;
    end
    fprintf(fid, solver_output);
    fclose(fid);
    if strfind(solver_output,'Wallclock timeout')
        msg = sprintf('Solver Result reached TIMEOUT. Check %s', ...
            tmp_file);
        display_msg(msg, MsgType.RESULT, 'Kind2Utils2.extract_answer', '');
        return;
    end

    try
        xDoc = xmlread(tmp_file);
    catch
        msg = sprintf('Can not read file %s', ...
            tmp_file);
        display_msg(msg, MsgType.ERROR, 'Kind2Utils2.extract_answer', '');
        return
    end
    xAnalysis = xDoc.getElementsByTagName('Analysis');
    nbSafe = 0;
    nbUnsafe = 0;
    for idx_analys=0:xAnalysis.getLength-1
        node_name = char(xAnalysis.item(idx_analys).getAttribute('top'));
        [main_node_struct, status] = LustrecUtils.extract_node_struct(lus_full_path, node_name);
        if status
            return;
        end
        xProperties = xAnalysis.item(idx_analys).getElementsByTagName('Property');
        for idx_prop=0:xProperties.getLength-1
            property = xProperties.item(idx_prop);
            prop_name = char(xProperties.item(idx_prop).getAttribute('name'));
            try
                answer = ...
                    property.getElementsByTagName('Answer').item(0).getTextContent;
            catch
                answer = 'ERROR';
            end

            if strcmp(answer, 'valid')
                answer = 'SAFE';
                if valid == -1; valid = 1; end
            elseif strcmp(answer, 'falsifiable')
                answer = 'UNSAFE';
                valid = 0;
            end

            if strcmp(answer, 'UNSAFE')

                xml_cex = property.getElementsByTagName('CounterExample');
                if xml_cex.getLength > 0
                    CEX_XML = xml_cex;
                    [IN_struct_i, ~] =...
                        Kind2Utils2.Kind2CEXTostruct(main_node_struct, ...
                        CEX_XML, node_name);
                    IN_struct = [IN_struct, IN_struct_i];
                else
                    msg = sprintf('Could not parse counter example for node %s and property %s from %s', ...
                        node_name, prop_name, solver_output);
                    display_msg(msg, MsgType.ERROR, 'Property Checking', '');
                end
                nbUnsafe = nbUnsafe + 1;
            end
            if strcmp(answer, 'SAFE')
                nbSafe = nbSafe + 1;
            end
            msg = sprintf('Solver Result for node %s of property %s is %s', ...
                node_name, prop_name, answer);
            display_msg(msg, MsgType.INFO, 'Kind2Utils2.extract_answer', '');
        end
    end
    msg = sprintf('Number of properties SAFE are %d', ...
        nbSafe);
    display_msg(msg, MsgType.INFO, 'Kind2Utils2.extract_answer', '');
    msg = sprintf('Number of properties UNSAFE are %d', ...
        nbUnsafe);
    display_msg(msg, MsgType.INFO, 'Kind2Utils2.extract_answer', '');
end

