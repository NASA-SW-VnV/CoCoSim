function AutoLayout(address)
% AUTOLAYOUT Make a system more readable by automatically laying out all
%   system components (blocks, lines, annotations).
%
%   Inputs:
%       address     Simulink system name or path.
%
%   Outputs:
%       N/A
%
%   Example:
%       external_lib.AutoLayout.AutoLayout('AutoLayoutDemo')
%           Modifies the AutoLayoutDemo system with one that performs the same
%           functionally, but is laid out to be more readable.

    %% Constants:
    % Getting parameters for the tool to determine its behaviour
    GRAPHING_METHOD = external_lib.AutoLayout.getAutoLayoutConfig('graphing_method', 'auto'); %Indicates which graphing method to use
    SHOW_NAMES = external_lib.AutoLayout.getAutoLayoutConfig('show_names', 'no-change'); %Indicates which block names to show
    PORTLESS_RULE = external_lib.AutoLayout.getAutoLayoutConfig('portless_rule', 'top'); %Indicates how to place portless blocks
    INPORT_RULE = external_lib.AutoLayout.getAutoLayoutConfig('inport_rule', 'none'); %Indicates how to place inports
    OUTPORT_RULE = external_lib.AutoLayout.getAutoLayoutConfig('outport_rule', 'none'); %Indicates how to place outports
    SORT_PORTLESS = external_lib.AutoLayout.getAutoLayoutConfig('sort_portless', 'blocktype'); %Indicates how to group portless blocks
    NOTE_RULE = external_lib.AutoLayout.getAutoLayoutConfig('note_rule', 'on-right'); %Indicates what to do with annotations

    function ErrorInvalidConfig(config)
        % Call this if a config setting was given an invalid value
        %
        % config is the name of the config, not value.

        error(['Error using ' mfilename ':' char(10) ...
            ' Invalid config parameter: ' config '.' char(10) ...
            ' Please fix in the config.txt.'])
    end

    %%
    % Check number of arguments
    try
        assert(nargin == 1)
    catch
        error(' Wrong number of arguments.');
    end

    % Check address argument
    % 1) Check model at address is open
    try
        assert(ischar(address));
        assert(bdIsLoaded(bdroot(address)));
    catch
        error(' Invalid argument: address. Model may not be loaded or name is invalid.');
    end

    % 2) Check that model is unlocked
    try
        assert(strcmp(get_param(bdroot(address), 'Lock'), 'off'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ...
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            error('File is locked');
        end
    end

    %% Get blocks in address
    systemBlocks = find_system(address, 'LookUnderMasks', 'all', 'SearchDepth', 1);
    systemBlocks = systemBlocks(2:end); %Remove address itself

    %% Make sum blocks rectangular so that they will look better
    external_lib.AutoLayout.GeneralPurpose.makeSumsRectangular(systemBlocks);

    %%
    % Find which blocks have no ports
    portlessBlocks = external_lib.AutoLayout.getPortlessBlocks(systemBlocks);

    % Check that portless_rule is set properly
    if ~external_lib.AutoLayout.AinB(PORTLESS_RULE, {'top', 'left', 'bottom', 'right', 'same_half_vertical', 'same_half_horizontal'})
        ErrorInvalidConfig('portless_rule')
    end

    % Find where to place portless blocks in the final layout
    [portlessInfo, smallOrLargeHalf] = external_lib.AutoLayout.getPortlessInfo(PORTLESS_RULE, systemBlocks, portlessBlocks);

    %%
    % 1) For each block, show or do not show its name depending on the SHOW_NAMES
    % parameter.
    % 2) Create a map that contains the info about whether the block should show its
    % name
    if strcmp(SHOW_NAMES, 'no-change')
        % Find which block names are showing at the start
        nameShowing = containers.Map();
        for i = 1:length(systemBlocks)
            if strcmp(get_param(systemBlocks(i), 'ShowName'), 'on')
                nameShowing(getfullname(systemBlocks{i})) = 'on';
                set_param(systemBlocks{i}, 'ShowName', 'off')
            elseif strcmp(get_param(systemBlocks(i), 'ShowName'), 'off')
                nameShowing(getfullname(systemBlocks{i})) = 'off';
            end
        end
    end

    %% Determine which initial layout graphing method to use
    % Determine which external software to use:
    %   1) MATLAB's GraphPlot objects; or
    %   2) Graphviz (requires separate install)
    % based on the configuration parameters and current version of MATLAB
    if strcmp(GRAPHING_METHOD, 'auto')
        % Check if MATLAB version is R2015b or newer (i.e. greater-or-equal to 2015b)
        ver = version('-release');
        ge2015b = str2num(ver(1:4)) > 2015 || strcmp(ver(1:5),'2015b');
        if ge2015b
            % Graphplot
            initLayout = @external_lib.AutoLayout.GraphPlot_Portion.GraphPlotLayout;
        else
            % Graphviz
            initLayout = @GraphvizLayout;
        end
    elseif strcmp(GRAPHING_METHOD, 'graphplot')
        % Graphplot
        initLayout = @external_lib.AutoLayout.GraphPlot_Portion.GraphPlotLayout;
    elseif strcmp(GRAPHING_METHOD, 'graphviz')
        % Graphviz
        initLayout = @GraphvizLayout;
    else
        ErrorInvalidConfig('graphing_method')
    end

    %% Get the first intial layout using a graphing algorithm
    initLayout(address);
    % If using GraphvizLayout, the layout at this point will be organized based on
    % the GraphPlot and the blocks will be resized to the same size
    %%
    % blocksInfo -  keeps track of where to move blocks so that they can all be
    %               moved at the end as opposed to throughout all of AutoLayout
    blocksInfo = external_lib.AutoLayout.getBlocksInfo(address);

    %% Show/hide block names (initLayout may inadvertently set it off)
    if strcmp(SHOW_NAMES, 'no-change')
        % Return block names to be showing or hidden, as they were initially
        for i = 1:length(systemBlocks)
            if strcmp(nameShowing(getfullname(systemBlocks{i})), 'on')
                set_param(systemBlocks{i}, 'ShowName', 'on')
            else
                % This should be redundant with the implementation, but is in place as a fail-safe
                set_param(systemBlocks{i}, 'ShowName', 'off')
            end
        end
    elseif strcmp(SHOW_NAMES, 'all')
        % Show all block names
        for i = 1:length(systemBlocks)
            set_param(systemBlocks{i}, 'ShowName', 'on')
        end
    elseif strcmp(SHOW_NAMES, 'none')
        % Show no block names
        for i = 1:length(systemBlocks)
            set_param(systemBlocks{i}, 'ShowName', 'off')
        end
    else
        ErrorInvalidConfig('show_names')
    end

    %%
    % 1) Remove portless blocks from blocksInfo (they will be handled separately)
    % 2) Add the position information of the portless block to the struct array of
    % portless blocks
    % Go backwards to remove elements without disrupting the indices that need to be
    % checked after
    for i = length(blocksInfo):-1:1
        for j = 1:length(portlessInfo)
            if strcmp(blocksInfo(i).fullname, portlessInfo{j}.fullname)
                portlessInfo{j}.position = blocksInfo(i).position;
                blocksInfo(i) = [];
                break
            end
        end
    end

    %%
    % Find relative positioning of blocks in the layout from initLayout
    layout = external_lib.AutoLayout.getRelativeLayout(blocksInfo); %layout will also take over the role of blocksInfo
    external_lib.AutoLayout.updateLayout(address, layout); % Only included here for feedback purposes

    %%
    [layout, portlessInfo] = external_lib.AutoLayout.resizeBlocks(layout, portlessInfo);

    layout = external_lib.AutoLayout.fixSizeOfBlocks(layout);

    % Update block positions according to layout that was changed by external_lib.AutoLayout.resizeBlocks()
    % and external_lib.AutoLayout.fixSizeOfBlocks()
    external_lib.AutoLayout.updateLayout(address, layout);

    % Move blocks with single inport/outport so their port is in line with
    % the source/destination port
    layout = external_lib.AutoLayout.vertAlign(layout);
    % % layout = easyAlign(layout); %old method, still relevant since it attempts to cover more cases

    layout = external_lib.AutoLayout.layout2(address, layout, systemBlocks);

    % Align inport/outport blocks if set to do so by inport/outport rules
    if strcmp(INPORT_RULE, 'left_align')
        % Left align the inports
        inports = find_system(address, 'LookUnderMasks', 'all','SearchDepth',1,'BlockType','Inport');
        layout = external_lib.AutoLayout.justifyBlocks(address, layout, inports, 1);
    elseif ~strcmp(INPORT_RULE, 'none')
        ErrorInvalidConfig('inport_rule')
    end

    if strcmp(OUTPORT_RULE, 'right_align')
        % Right align the outports
        outports = find_system(address, 'LookUnderMasks', 'all','SearchDepth',1,'BlockType','Outport');
        layout = external_lib.AutoLayout.justifyBlocks(address, layout, outports, 3);
    elseif ~strcmp(OUTPORT_RULE, 'none')
        ErrorInvalidConfig('outport_rule')
    end

    % Update block positions according to layout
    external_lib.AutoLayout.updateLayout(address, layout);

    %%
    % Check that sort_portless is set properly
    if ~external_lib.AutoLayout.AinB(SORT_PORTLESS, {'blocktype', 'masktype_blocktype', 'none'})
        ErrorInvalidConfig('sort_portless')
    end

    % Place blocks that have no ports in a line along the top/bottom or left/right
    % horizontally, depending on where they were initially in the system and the
    % PORTLESS_RULE.
    portlessInfo = external_lib.AutoLayout.repositionPortlessBlocks(portlessInfo, layout, PORTLESS_RULE, smallOrLargeHalf, SORT_PORTLESS);

    % Update block positions according to portlessInfo
    external_lib.AutoLayout.updatePortless(address, portlessInfo);

    %%
    % Get all the annotations
    annotations = find_system(address, 'LookUnderMasks', 'all','FindAll','on','SearchDepth',1,'Type','annotation');
    % Move all annotations to the right of the system, if necessary
    if ~(strcmp(NOTE_RULE, 'none') || strcmp(NOTE_RULE, 'on-right'))
        ErrorInvalidConfig('note_rule')
    else
        external_lib.AutoLayout.handleAnnotations(layout, portlessInfo, annotations, NOTE_RULE);
    end

    %%
    % Orient blocks left-to-right and place name on bottom
    %setOrientations(systemBlocks);
    external_lib.AutoLayout.GeneralPurpose.setNamePlacements(systemBlocks);

    %%
    % Zoom on system (if it ends up zoomed out that means there is
    % something near the borders)
    set_param(address, 'Zoomfactor', 'Fit to view');
end
