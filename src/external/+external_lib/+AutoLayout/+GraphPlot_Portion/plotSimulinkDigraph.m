function h = plotSimulinkDigraph(sys, dg)
% PLOTSIMULINKDIGRAPH Plot a digraph representing a Simulink (sub)system in the
%   same fashion as a Simulink diagram, i.e., layered, left-to-right, etc.
%
%   Inputs:
%       sys     Path of the system that the digraph represents.
%       dg      Digraph representation of the system sys.
%
%   Outputs:
%       h       GraphPlot object (see
%               www.mathworks.com/help/matlab/ref/graphplot.html)

    % Check first input
    try
        assert(ischar(sys));
    catch
        error('A string to a valid Simulink (sub)system must be provided.');
    end

    try
        assert(bdIsLoaded(bdroot(sys)));
    catch
        error('Simulink system provided is invalid or not loaded.');
    end

    % Check second input
    try
        assert(external_lib.AutoLayout.GraphPlot_Portion.isdigraph(dg));
    catch
        error('Digraph argument provided is not a digraph');
    end

    % Get sources
    src = find_system(sys, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'Inport');
    src = strcat(src,':b');     % Apply naming convention

    % Get sinks
    snk = find_system(sys, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'Outport');
    snk = strcat(snk,':b');     % Apply naming convention

    % Use Simulink-like plot options
    % Info on options: https://www.mathworks.com/help/matlab/ref/graph.plot.html
    ops = {'Layout', 'layered', 'Direction', 'right', 'AssignLayers', 'alap'};
    if ~isempty(src)
        ops = [ops 'Sources' {src}];
    end
    if ~isempty(snk)
        ops = [ops 'Sinks' {snk}];
    end

    % Plot
    h = plot(dg, ops{:});
end
