
function [IN_struct, time_max] = Kind2CEXTostruct(...
    node_struct, ...
    cex_xml, ...
    node_name)
    IN_struct = [];
    time_max = 0;
    nodes = cex_xml.item(0).getElementsByTagName('Node');
    if nodes.getLength == 0
        nodes = cex_xml.item(0).getElementsByTagName('Function');
    end
    node = [];
    for idx=0:(nodes.getLength-1)
        if strcmp(nodes.item(idx).getAttribute('name'), node_name)
            node = nodes.item(idx);
            break;
        end
    end
    if isempty(node)
        display_msg('Failed to parse CounterExample',...
            MsgType.ERROR, 'Kind2Utils2.Kind2CEXTostruct', '');
        return;
    end
    IN_struct.node_name = node_name;
    streams = node.getElementsByTagName('Stream');
    node_streams = {};
    node_streams_name = {};
    for i=0:(streams.getLength-1)
        if strcmp(streams.item(i).getParentNode.getAttribute('name'),...
                node_name) && ...
                strcmp(streams.item(i).getAttribute('class'),...
                'input')
            node_streams_name{numel(node_streams_name) + 1} = ...
                char(streams.item(i).getAttribute('name'));
            node_streams{numel(node_streams) + 1} = streams.item(i);
        end
    end
    if isfield(node_struct, 'inputs')
        node_inputs = node_struct.inputs;
        nb_in = numel(node_inputs);
        for i=1:nb_in
            input_name = node_inputs(i).name;
            id_stream = find(strcmp(input_name, node_streams_name));
            if isempty(id_stream)
                IN_struct.signals(i).name = input_name;
                IN_struct.signals(i).datatype = LusValidateUtils.get_slx_dt(node_inputs(i).datatype);
                %TODO dimension > 1 case
                IN_struct.signals(i).dimensions =  1;
                IN_struct.signals(i).values = [];
            else
                s_name = char(node_streams{id_stream}.getAttribute('name'));
                s_dt =  char(LusValidateUtils.get_slx_dt(node_streams{id_stream}.getAttribute('type')));

                IN_struct.signals(i).name = s_name;
                IN_struct.signals(i).datatype = s_dt;

                %TODO parse the type and extract dimension
                IN_struct.signals(i).dimensions =  1;

                [values, time_step] =...
                    LustrecUtils.extract_values(...
                    node_streams{id_stream}, s_dt);
                IN_struct.signals(i).values = values';
                time_max = max(time_max, time_step);
            end
        end
    else
        for i=1:numel(node_streams)
            s_name = char(node_streams{i}.getAttribute('name'));
            s_dt =  char(LusValidateUtils.get_slx_dt(node_streams{i}.getAttribute('type')));

            IN_struct.signals(i).name = s_name;
            IN_struct.signals(i).datatype = s_dt;

            %TODO parse the type and extract dimension
            IN_struct.signals(i).dimensions =  1;

            [values, time_step] =...
                LustrecUtils.extract_values(...
                node_streams{i}, s_dt);
            IN_struct.signals(i).values = values';
            time_max = max(time_max, time_step);
        end
    end
    min = -100; max_v = 100;
    for i=1:numel(IN_struct.signals)
        if numel(IN_struct.signals(i).values) < time_max + 1
            nb_steps = time_max +1 - numel(IN_struct.signals(i).values);
            dim = IN_struct.signals(i).dimensions;
            if strcmp(...
                    nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(IN_struct.signals(i).datatype),...
                    'bool')
                values = ...
                    LusValidateUtils.construct_random_booleans(...
                    nb_steps, min, max_v, dim);
            elseif strcmp(...
                    nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(IN_struct.signals(i).datatype),...
                    'int')
                values = ...
                    LusValidateUtils.construct_random_integers(...
                    nb_steps, min, max_v, IN_struct.signals(i).datatype, dim);
            elseif strcmp(...
                    IN_struct.signals(i).datatype,...
                    'single')
                values = ...
                    single(...
                    LusValidateUtils.construct_random_doubles(...
                    nb_steps, min, max_v, dim));
            else
                values = ...
                    LusValidateUtils.construct_random_doubles(...
                    nb_steps, min, max_v, dim);
            end
            IN_struct.signals(i).values =...
                [IN_struct.signals(i).values, values];
        end
    end
    IN_struct.time = (0:1:time_max)';
end

    


