
function [y_inlined, width, status] = inline_array(y_struct, time_step)
    % this function inline a multi-dimension array to a vector, it
    % follows the cullumn convention.

    status = 0;
    dim = y_struct.dimensions;
    if numel(dim)==1
        y_inlined = y_struct.values(time_step+1,:);
        width = dim;
    else
        width = prod(dim);
        %time dimension is the last dimension
        timeDimension = numel(size(y_struct.values));
        % put time as first dimension
        A = permute(y_struct.values, [timeDimension, 1:timeDimension-1]);
        y_inlined = A(time_step+1,:);
    end
end

