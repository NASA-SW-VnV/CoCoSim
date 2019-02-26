function GraphPlotLayout(address)
% GRAPHPLOTLAYOUT Creates a GraphPlot representing the system using MATLAB
%   functions and then lays out the system according to that plot.
%
%   Input:
%       address     System address in which to perform the analysis.
%
%   Output:
%       N/A

    dg = systemToDigraph(address);
    dg2 = addImplicitEdges(address, dg);

    defaultFigureVisible = get(0, 'DefaultFigureVisible');
    set(0, 'DefaultFigureVisible', 'off');    % Don't show the figure
    p = plotSimulinkDigraph(address, dg2);
    set(0,'DefaultFigureVisible', defaultFigureVisible);

    systemBlocks = p.NodeLabel';
    xs = p.XData;
    ys = p.YData;

    % keep = ~cellfun(@isempty,regexp(systemBlocks,'(:b$)','once'));
    % toss = ~cellfun(@isempty,regexp(systemBlocks,'(:[io][0-9]*$)','once')); % These aren't needed anymore
    % assert(all(xor(keep, toss)), 'Unexpected NodeLabel syntax.')
    % systemBlocks = cellfun(@(x) x(1:end-2), systemBlocks(keep), 'UniformOutput', false);
    % xs = xs(keep);
    % ys = ys(keep);
    % % systemBlocks(toss) = [];
    % % xs(toss) = [];
    % % ys(toss) = [];

    systemBlocks = cellfun(@(x) x(1:end-2), systemBlocks, 'UniformOutput', false);

    % Set semi-arbitrary scaling factors to determine starting positions
    scale = 90; % Pixels per unit increase in x or y in the plot
    scaleBack = 3; % Scale-back factor to determine block size

    for i = 1:length(systemBlocks)
        blockwidth  = scale/scaleBack;
        blockheight = scale/scaleBack;
        blockx      = scale * xs(i);
        blocky      = scale * (max(ys) + min(ys) - ys(i)); % Accounting for different coordinate system between the plot and Simulink

        % Keep the block centered where the node was
        left    = round(blockx - blockwidth/2);
        right   = round(blockx + blockwidth/2);
        top     = round(blocky - blockheight/2);
        bottom  = round(blocky + blockheight/2);

        pos = [left top right bottom];
        setPositionAL(systemBlocks{i}, pos);
    end

    % Try to fix knots caused by the arbitrary ordering of out/inputs to a node
    for i = 1:length(systemBlocks)
        ph = get_param(systemBlocks{i}, 'PortHandles');
        out = ph.Outport;
        if length(out) > 1
            arrangeSinks(systemBlocks{i}, true);
        end
    end
    for i = 1:length(systemBlocks)
        ph = get_param(systemBlocks{i}, 'PortHandles');
        in = ph.Inport;
        if length(in) > 1
            arrangeSources(systemBlocks{i}, true);
        end
    end
end