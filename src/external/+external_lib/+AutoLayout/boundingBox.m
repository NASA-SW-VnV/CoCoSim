function bounds = boundingBox(object)
% BOUNDINGBOX Find the bounding box of a Simulink object. Supports blocks,
%   lines, and annotations.
%
%   Inputs:
%       object  The object itself (fullname or handle).
%
%   Outputs:
%       bounds  The bounds of the object as: [left, top, right, bottom] in pixels.

    objectType = get_param(object, 'Type');

    switch objectType
        case 'block'
            bounds = blockBounds(object);
        case 'line'
            bounds = lineBounds(object);
        case 'annotation'
            bounds = annotationBounds(object);
        otherwise
            error(['Error in ' mfilename '. Expected type of object to be ''block'', ''line'', or ''annotation'''])
    end
end

function bounds = blockBounds(block)
    bounds = get_param(block,'Position');
end

function bounds = lineBounds(line)
    points = get_param(line, 'Points');
    bounds = [min(points(:,1)) min(points(:,2)) max(points(:,1)) max(points(:,2))];
end

function bounds = annotationBounds(note)
    ob = get_param(note,'object');
    bounds = ob.getBounds;
end

% function bounds = annotationBounds(note)
%
% %Note1: Prior to 20XX, annotation position was given as an anchor point
% %   (in top-left generally).
% %   First version since change is between 2012b and 2014b (inclusive).
% %Note2: Prior to 20YY, annotation visual position depeneded on
% %   HorizontalAlignment and VerticalAlignment parameters.
% %   First version since change is between 2015b and 2016b (inclusive).
%
% ver = version('-release');
%
% isAnchorVer = str2num(ver(1:4)) < 2014 ...
%     | (str2num(ver(1:4)) == 2014 & strcmp(str2num(ver(5)),'a')); % if pre-2014b
% isPositionWithAlignmentVer = str2num(ver(1:4)) < 2016; % if pre-2016a
%
% pos = get_param(note,'Position');
% x = pos(1);
% y = pos(2);
%
% if isAnchorVer
%     % Find with based on the text
%     width = annotationStringWidth(note, get_param(note,'Text')); %there's some problem with the method of finding the width
%     height = annotationStringHeight(note, get_param(note,'Text')); %presumably have same issue with height
% else
%     width = pos(3) - pos(1);
%     height = pos(4) - pos(2);
% end
%
% if isPositionWithAlignmentVer
%
%     hAlign = get_param(note, 'HorizontalAlignment');
%     switch hAlign
%         case 'center'
%             adjustX = ceil(0.5*width); %ceil to avoid underestimate
%         case 'right'
%             adjustX = width;
%         case 'left'
%             adjustX = 0;
%         otherwise
%             error(['Error in ' mfilename ', unexpected HorizontalAlignment parameter value.']);
%     end
%
%     vAlign = get_param(note, 'VerticalAlignment');
%     switch vAlign
%         case 'middle'
%             adjustY = ceil(0.5*height); %ceil to avoid underestimate
%         case 'bottom'
%             adjustY = height;
%         case 'top'
%             adjustY = 0;
%         otherwise
%             error(['Error in ' mfilename ', unexpected VerticalAlignment parameter value.']);
%     end
%
%     x = x - adjustX;
%     y = y - adjustY;
% end
%
% bounds = [x, y, x+width, y+height];
% end