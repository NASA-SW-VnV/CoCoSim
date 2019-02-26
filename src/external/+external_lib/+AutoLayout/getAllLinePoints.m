function linePoints = getAllLinePoints(lines)
% GETALLLINEPOINTS Return a cell array where each element is the set of points
%   associated with each of the corresponding input lines.
%
%   Inputs:
%       lines       Array of lines.
%
%   Outputs:
%       linepoints  Cell array of line points.

    linePoints = {};
    for i = 1:length(lines)
        linePoints{i} = get_param(lines(i), 'Points');
    end
end