function [x,y] = rectCenter(positions)
% RECTCENTER Find the coordinates of the center of a rectangle.
%
%   Inputs:
%       positions   Cell array of vectors of coordinates in the form
%                   [left top right bottom].
%
%   Outputs:
%       x           Cell array of x coordinates of the rectangle centers.
%       y           Cell array of y coordinates of the rectangle centers.


    x = zeros(1,length(positions));
    y = zeros(1,length(positions));
    for i = 1:length(positions)
        position = positions{i};
        x(i) = (position(1) + position(3)) / 2; %(left + right)/2
        y(i) = (position(2) + position(4)) / 2; %(top + bottom)/2
    end
end