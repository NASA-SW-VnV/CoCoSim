function handleAnnotations(layout, portlessInfo, annotations, note_rule)
% HANDLEANNOTATIONS Move portless blocks to the right side of the system.
%   The annotations should not extend too far below the bottom of the
%   system.
%
%   Inputs:
%       layout          As returned by getRelativeLayout.
%       portlessInfo    As returned by getPortlessInfo.
%       annotations     Vector of all of the annotations in the system.
%       note_rule       Rule indicating what to do with annotations. See
%                       NOTE_RULE in config.txt.
%
%   Outputs:
%       N/A

    if strcmp(note_rule, 'on-right')
        arbitraryBuffer = 50;

        ignorePortlessBlocks = false;
        [~,topBound,rightBound,botBound] = sideExtremes(layout, portlessInfo, ignorePortlessBlocks);

        top = topBound;
        left = rightBound + arbitraryBuffer;

        widest = 0;

        for i = 1:length(annotations)

            % Find width and height to maintain during repositioning
            bounds = boundingBox(annotations(i));

            width = bounds(3) - bounds(1);
            height = bounds(4) - bounds(2);

            % Get current position
            pos = get_param(annotations(i),'Position');

            adjustX = pos(1) - bounds(1);
            adjustY = pos(2) - bounds(2);

            if length(pos) == 2 % Older MATLAB version
                set_param(annotations(i),'Position', [left + adjustX, top + adjustY])
            elseif length(pos) == 4
                set_param(annotations(i),'Position', [left + adjustX, top + adjustY, left + adjustX + width, top + adjustY + height])
            else
                error(['Error in ', mfilename, '. Expecting 2 or 4 values in annotation position parameter.'])
            end

            if width > widest
                widest = width;
            end

            if top + height > botBound % New annotation column to avoid extending too far down
                left = left + widest + arbitraryBuffer;
                top = topBound;
                widest = 0;
            else
                top = top + height + arbitraryBuffer;
            end
        end
    elseif ~strcmp(note_rule, 'none')
        % Invalid config setting should have already been caught
        error(['Error using ' mfilename ':' char(10) ...
            ' Something went wrong with the config parameter.'])
    end % elseif strcmp(note_rule, 'none'), then don't move the annotations at all
end