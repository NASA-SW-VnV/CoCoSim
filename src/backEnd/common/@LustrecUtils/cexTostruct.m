
function [ds, time_max] = cexTostruct(...
        cex_xml, ...
        node_name,...
        inports)
    IN_struct = [];

    nodes = cex_xml.item(0).getElementsByTagName('Node');
    node = [];
    for idx=0:(nodes.getLength-1)
        if strcmp(nodes.item(idx).getAttribute('name'), node_name)
            node = nodes.item(idx);
            break;
        end
    end
    if isempty(node)
        return;
    end
    streams = node.getElementsByTagName('Stream');
    stream_names = {};
    for i=0:(streams.getLength-1)
        s = streams.item(i).getAttribute('name');
        stream_names{i+1} = char(s);
    end
    time_max = 0;
    for i=1:numel(inports)
        IN_struct.signals(i).name = inports(i).name;
        IN_struct.signals(i).datatype = ...
            LusValidateUtils.get_slx_dt(inports(i).datatype);
        if isfield(inports(i), 'dimensions')
            IN_struct.signals(i).dimensions = inports(i).dimensions;
        else
            IN_struct.signals(i).dimensions =  1;
        end

        stream_name = inports(i).name;
        stream_index = find(strcmp(stream_names, stream_name), 1);
        if isempty(stream_index)
            IN_struct.signals(i).values = [];
        else
            [values, time_step] =...
                LustrecUtils.extract_values(...
                streams.item(stream_index-1), inports(i).datatype);
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
    ds = Simulink.SimulationData.Dataset(IN_struct);
end

