function dgNew = addImplicitEdges(sys, dg)
% ADDIMPLICITEDGES Add edges to a digraph representing the implicit connections
%    between goto/froms.
%
%   Inputs:
%       sys     Path of the system that the digraph represents.
%       dg      Digraph representation of the system sys.
%
%   Outputs:
%       dgNew   Updated digraph.

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

    % Duplicate
    dgNew = dg;

    % Add Goto/Froms as edges
    gotos = find_system(sys, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'Goto');
    froms = find_system(sys, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'From');

    % For each Goto tags, find the corresponding From tags
    for i = 1:length(gotos)
        subFroms = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findFromsInScope(gotos{i});
        for j = 1:length(subFroms)
            snk = getRootInSys(subFroms{j});
            if(isempty(snk))
                continue
            end
            srcName = external_lib.AutoLayout.GraphPlot_Portion.applyNamingConvention(gotos{i});
            snkName = external_lib.AutoLayout.GraphPlot_Portion.applyNamingConvention(snk);
            % If the implicit edge does not exist in the graph, add it to the
            % graph
            if ~edgeExists(dgNew, srcName, snkName)
                dgNew = addedge(dgNew, srcName, snkName, 1);
            end
        end
    end
    % For each From tags, find the corresponding Goto tags
    for i = 1:length(froms)
        subGotos = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findGotosInScope(froms{i});
        for j = 1:length(subGotos)
            src = getRootInSys(subGotos{j});
            if(isempty(src))
                continue
            end
            srcName = external_lib.AutoLayout.GraphPlot_Portion.applyNamingConvention(src);
            snkName = external_lib.AutoLayout.GraphPlot_Portion.applyNamingConvention(froms{i});
            % If the implicit edge does not exist in the graph, add it to the
            % graph
            if ~edgeExists(dgNew, srcName, snkName)
                dgNew = addedge(dgNew, srcName, snkName, 1);
            end
        end
    end

    % Add Data Store Read/Writes as edges
    writes = find_system(sys, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'DataStoreWrite');
    reads = find_system(sys, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'DataStoreRead');

    % For each DataStoreWrite, find the corresponding DataStoreRead
    for i = 1:length(writes)
        subReads = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findReadsInScope(writes{i});
        for j = 1:length(subReads)
            snk = getRootInSys(subReads{j});
            if(isempty(snk))
                continue
            end
            srcName = external_lib.AutoLayout.GraphPlot_Portion.applyNamingConvention(writes{i});
            snkName = external_lib.AutoLayout.GraphPlot_Portion.applyNamingConvention(snk);
            % If the implicit edge does not exist in the graph, add it to the
            % graph
            if ~edgeExists(dgNew, srcName, snkName)
                dgNew = addedge(dgNew, srcName, snkName, 1);
            end
        end
    end
    % For each DataStoreReads
    for i = 1:length(reads)
        subWrites = external_lib.AutoLayout.Utility.FindingConnectedBlocks.findWritesInScope(reads{i});
        for j = 1:length(subWrites)
            src = getRootInSys(subWrites{j});
            if(isempty(src))
                continue
            end
            srcName = external_lib.AutoLayout.GraphPlot_Portion.applyNamingConvention(src);
            snkName = external_lib.AutoLayout.GraphPlot_Portion.applyNamingConvention(reads{i});
            % If the implicit edge does not exist in the graph, add it to the
            % graph
            if ~edgeExists(dgNew, srcName, snkName)
                dgNew = addedge(dgNew, srcName, snkName, 1);
            end
        end
    end

    function root = getRootInSys(blk)
        % Recursively get parent system of the block until reaching sys.
        % If blk is directly within sys, then it is "root",
        % otherwise "root" is a subsystem directly within sys that contains
        % blk at any depth (if it exists).
        %
        % The point is to find which block to create an edge with when the
        % data flow implicitly goes into a subsystem.
        p = get_param(blk, 'Parent');
        if strcmp(p, sys)
            root = blk;
        elseif(isempty(p))
                root = '';
        else
            root = getRootInSys(p);
        end
    end

    % Check if the edge exists in the current graph
    function exists = edgeExists(dg, source, sink)
        exists = false;
        for z = 1:size(dg.Edges, 1)
            edgeFound = strcmp(source, dg.Edges{z,1}{1}) && strcmp(sink, dg.Edges{z,1}{2});
            if edgeFound
                exists = true;
            end
        end
    end
end
