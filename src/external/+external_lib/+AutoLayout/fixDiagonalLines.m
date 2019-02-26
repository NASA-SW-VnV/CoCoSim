function fixDiagonalLines(systemLines)
% FIXDIAGONALLINES Remove diagonal lines by checking all pairs of points
%   and if the pair form a diagonal line segment, then redraws the line
%   with two 90 degree turns instead.
%
%   Inputs:
%       systemLines     Lines that are checked to see if they are diagonal.
%
%   Outputs:
%       N/A

    for i = 1:length(systemLines)
        line = systemLines(i);
        linePoints = get_param(line, 'points');
        for j = 1:size(linePoints,1) - 1
            % Determine if the next point in the line is on the same row or
            % column. If not, the line is diagonal
            if linePoints(j,1) ~= linePoints(j+1,1) && linePoints(j,2) ~= linePoints(j+1,2)
                firstPoint = linePoints(1,:);
                sLastPoint = linePoints(end-1,:); % 2nd last point
                lastPoint = linePoints(end,:);
                middlePixel = floor((firstPoint(1) + lastPoint(1)) / 2);
                firstMidpoint = [middlePixel, firstPoint(2)];
                secondMidpoint = [middlePixel, sLastPoint(2)];
                points = [firstPoint; firstMidpoint; secondMidpoint; sLastPoint; lastPoint];
                set_param(line, 'points', points);
            end
        end
    end
end