function [body, variables, external_nodes, external_libraries] =...
        write_body(subsys, main_sampleTime, lus_backend, coco_backend, xml_trace)
    %% Go over SS Content
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
    %
    %
    variables = {};
    body = {};
    external_nodes = {};
    external_libraries = {};


    fields = fieldnames(subsys.Content);
    fields = ...
        fields(cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));
    if numel(fields)>=1
        xml_trace.create_Variables_Element();
    end
    for i=1:numel(fields)
        blk = subsys.Content.(fields{i});
        [b, status] = nasa_toLustre.utils.getWriteType(blk);
        if status
            continue;
        end
        try
            b.write_code(subsys, blk, xml_trace, lus_backend, coco_backend, main_sampleTime);
        catch me
            display_msg(sprintf('Translation to Lustre of block %s has failed.', HtmlItem.addOpenCmd(blk.Origin_path)),...
                MsgType.ERROR, 'write_body', '');
            display_msg(me.getReport(), MsgType.DEBUG, 'write_body', '');
        end
        code = b.getCode();
        if iscell(code)
            body = [body, code];
        else
            body{end+1} = code;
        end
        variables = [variables, b.getVariables()];
        external_nodes = [external_nodes, b.getExternalNodes()];
        external_libraries = [external_libraries, b.getExternalLibraries()];
    end
end
