
function [values, time_step] = extract_values( stream, dt)
    stream_values = stream.getElementsByTagName('Value');
    for idx=0:(stream_values.getLength-1)
        val = char(stream_values.item(idx).getTextContent);
        if strcmp(val, 'False') || strcmp(val, 'false')
            values(idx+1) = false;
        elseif strcmp(val, 'True') || strcmp(val, 'true')
            values(idx+1) = true;
        else
            values(idx+1) = feval(dt, str2num(val));
        end
    end

    time_step = idx;
end

