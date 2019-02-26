classdef TplainParser < handle
% TPLAINPARSER A class for parsing a Graphviz output txt file, and moving Simulink
%   blocks to their appropriate locations.
%
%   Examples:
%       1)
%       g = external_lib.AutoLayout.Graphviz_Portion.TplainParser('testModel', testModel.txt, containers.Map());
%       g.plain_wrappers;
%
%       2)
%       [filename, map] = external_lib.AutoLayout.Graphviz_Portion.dotfile_creator('testModel');
%       h = external_lib.AutoLayout.Graphviz_Portion.TplainParser('testModel', filename, map);
%       h.plain_wrappers;

    properties
        RootSystemName  % Simulink model name (or top-level system name).
        Filename        % Name of the Graphviz output txt file.
        Map             % (See dotfile_creator).
    end

    methods
        function object = external_lib.AutoLayout.Graphviz_Portion.TplainParser(rootSystemName, filename, replacementMap)
        % Constructor for the TplainParser object. This object represents
        %   the mapping between Graphviz node locations and Simulink block
        %   locations.
        %
        %   Inputs:
        %       rootSystemName      Simulink model name (or top-level system name).
        %       filename            Name of the Graphviz output txt file.
        %       replacementMap      (See dotfile_creator).
        %
        %   Outputs:
        %       object              TplainParser object.

            object.RootSystemName = rootSystemName;
            object.Filename = filename;
            object.Map = replacementMap;
        end

        function plain_wrappers(object)
        % Parse the Graphviz output file and find where to move the Simulink
        %   blocks in the system.
        %
        %   Inputs:
        %       object    TplainParser object.
        %
        %   Outputs:
        %       N/A

            filename = [object.Filename '-plain.txt'];
            [mapObj, graphinfo] = parse_the_Tplain(object, filename);
            find_the_right_spot(object, mapObj, graphinfo);
%             subsystems = find_system(object.RootSystemName,'Blocktype','SubSystem');
%             sublength = length(subsystems);
%             for z = 1:sublength
%                 protofilename = subsystems{z};
%                 protofilename = strrep(protofilename,'/' ,'' );
%                 filename = [protofilename '-plain.txt']
%                 [mapObj, graphinfo] = parse_the_Tplain(object, filename );
%                 go_to_the_right_spot(object, subsystems{z},mapObj, graphinfo);
%             end
        end

        function [mapObj, graphinfo] = parse_the_Tplain(object, filename)
        % Parse the Graphviz output txt file to construct objects with more
        %   direct mappings from block names to coordinates in the Graphviz
        %   graph.
        %
        %   Inputs:
        %       object    TplainParser object.
        %       filename  Name of the Graphviz output txt file.
        %
        %   Outputs:
        %       mapObj    Mapping from blocks to coordinates and dimensions
        %                 those blocks within the Graphviz graph (this is a
        %                 different coordinate system than MATLAB's).
        %                 The keys are block names, the values of the map
        %                 are cell arrays where:
        %                 value{1} = center coord of x axis
        %                 value{2} = center coord of y axis
        %                 value{3} = block width
        %                 value{4} = block height
        %
        %       graphinfo   Info for width and height of the graph.
        %                   graphinfo(1) - unused
        %                   graphinfo(2) - width
        %                   graphinfo(3) - height

            inputfile = fopen(filename);
            tline = fgetl(inputfile);
            C = textscan(tline, '%s %f %f %f');
            % Info for width and height of window
            graphinfo = [C{2} C{3} C{4}];

            mapObj = containers.Map();
            while 1
                % Get a line from the input file
                tline = fgetl(inputfile);
                % Quit if end of file
                if ~ischar(tline)
                    break
                end
                C = textscan(tline, '%s %s %f %f %f %f %s %s %s %s %s');
                if strcmp(C{1}{1}, 'node')

                    % C{3} - desired block center X coord
                    % C{4} - desired block center Y coord
                    % C{5} - desired block width
                    % C{6} - desired block height
                    values = {C{3} C{4} C{5} C{6}};
                    mapkey = C{2}{1}; % Block name

                    % Used for blocks names using certain characters
                    itemsToReplace = keys(object.Map);
                    for item = 1:length(itemsToReplace)
                        mapkey = strrep(mapkey, itemsToReplace{item}, object.Map(itemsToReplace{item}));
                    end

                    mapObj(mapkey) = values;
                end
                % Note that Graphviz also gives information about the edges
                % in the graph, but this information is not used.
            end
            fclose(inputfile);
        end

        function find_the_right_spot(object, mapObj, graphinfo)
        % Find the right position for blocks using the info from graphinfo and mapObj.
        %
        %   Inputs:
        %       object      TplainParser object.
        %       mapObj      (same as in parse_the_Tplain in this file)
        %       graphinfo   (same as in parse_the_Tplain in this file)
        %
        %   Outputs:
        %       N/A

            % Get blocks in address
            systemBlocks = find_system(object.RootSystemName, 'LookUnderMasks', 'all', 'SearchDepth',1);
            systemBlocks = systemBlocks(2:end); % Remove address itself

            blocklength = length(systemBlocks);
            width = round(graphinfo(2)); % This is unused currently, but is left in case it is needed in the future
            height = round(graphinfo(3));

            for z = 1:blocklength
                subsystemblocksName = get_param(systemBlocks{z}, 'Name');
                % Block's position information from Graphviz
                blockPosInfo = mapObj(subsystemblocksName);

                blockwidth  = blockPosInfo{3};
                blockheight = blockPosInfo{4};
                blockx      = blockPosInfo{1};
                blocky      = round(height - blockPosInfo{2}); % Account for different coordinate system between Graphviz and MATLAB

                left    = round(blockx - blockwidth/2);
                right   = round(blockx + blockwidth/2);
                top     = round(blocky - blockheight/2);
                bottom  = round(blocky + blockheight/2);

                pos = [left top right bottom];
                external_lib.AutoLayout.GeneralPurpose.setPositionAL(systemBlocks{z}, pos);
            end
        end
    end
end
