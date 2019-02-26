function fixLineOverBlock(allLines, allBlocks)
% FIXLINEOVERBLOCK Draw new lines that do not go through any of the blocks in
%   the system.
%
%   Inputs:
%       allLines     All lines in the system.
%       allBlocks    All blocks in the the system.
%
%   Outputs:
%       N/A

    for i = 1:length(allBlocks)
        position = get_param(allBlocks{i}, 'Position');
        for j = 1:length(allLines)
            points = get_param(allLines(j), 'points');
            numPoints = length(points);
            for k = 1:2
                for l = 1:numPoints - 1
                    a = [position(1), position(k*2); position(3), position(k*2)];
                    b = [points(l), points(l+numPoints); points(l+1), points(l+numPoints+1)];
                    if doLinesIntersect(a, b)
                        src = get_param(allLines(j), 'SrcBlockHandle');
                        srcPos = get_param(src, 'Position');
                        points(l) = srcPos(3) + 25;
                        tmp = points(l+1, :);
                        points(l+1) = srcPos(3) + 25;
                        points(l+numPoints+1) = points(l+numPoints+1) - 10;
                        points = [points; tmp];
                        set_param(allLines(j), 'points', points);
                    end
                end
            end
        end
    end
end

function bool = doLinesIntersect(a, b)
    bool = ((a(1) <= b(2)) && (a(2) >= b(1)) && (a(3) <= b(4)) && (a(4) >= b(3))) ...
        || ((a(1) <= b(2)) && (a(2) >= b(1)) && (a(3) >= b(4)) && (a(4) <= b(3)));
end