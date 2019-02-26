function moveBlocks(address, blocks, positions)
% MOVEBLOCKS Move blocks in address to the given positions.
%
%   Inputs:
%       address     Simulink system name or path.
%       blocks      Cell array of full block names.
%       positions   Cell array of positions corresponding with blocks (i.e.
%                   blocks{i} should be moved to positions{i}; blocks and
%                   positions are of the same length).
%                   Each value should be in a vector as returned by
%                   get_param(gcb, 'Position').
%
%   Outputs:
%       N/A
%
%   Example:
%       moveBlocks('AutoLayoutDemo',{'AutoLayoutDemo/In1', ...
%           'AutoLayoutDemo/In2'}, {[-35,50,-15,70],[-35,185,-15,205]})

    % Check number of arguments
    try
        assert(nargin == 3)
    catch
        error('Wrong number of arguments.');
    end

    % Check address argument
    % 1) Check model at address is open
    try
       assert(ischar(address));
       assert(bdIsLoaded(bdroot(address)));
    catch
        error('Invalid argument: address. Model may not be loaded or name is invalid.');
    end

    % 2) Check that model is unlocked
    try
        assert(strcmp(get_param(bdroot(address), 'Lock'), 'off'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ...
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            error('File is locked.');
        end
    end

    blockLength = length(blocks);
    for k = 1:blockLength
        set_param(blocks{k}, 'Position', positions{k});

        %TODO
        %get block pos at this point, if size is less than indicated by
        %blocksInfo(z).position then may need to increase pos(3) or pos(4)
        %by ~5 as appropriate
        %(main reason to adjust size would be to ensure sufficient space
        %for text)
        %(may make sense to include this outside this function to keep this
        %general)
    end
    redraw_lines(address, 'autorouting', 'on');
end