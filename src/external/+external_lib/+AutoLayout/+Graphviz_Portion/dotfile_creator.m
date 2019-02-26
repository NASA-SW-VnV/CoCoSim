function [fullname, replacementMap] = dotfile_creator(name)
% DOTFILE_CREATOR Parses a system and creates a Graphviz dotfile.
%
%   Inputs:
%       name            Name of the Simulink file to be processed.
%
%   Outputs:
%       fullname        Name of the dotfile, as well as the resulting
%                       Graphviz output.
%       replacementMap  A containers.Map. Characters in block names that
%                       aren't supported in the dotfile (values in the map)
%                       will be replaced by another string (keys in the
%                       map), later block names will need to be restored by
%                       replacing the keys with the values in block names.
%
%   Example:
%       filename = external_lib.AutoLayout.Graphviz_Portion.dotfile_creator('testModel');

    %external_lib.AutoLayout.redraw_lines(name)
    %external_lib.AutoLayout.redraw_lines(name,autorouting,off)
    function string = subwidth(number)
        % Get dimensions for a SubSystem for the dotfile graph
        if number > 3
            height = 60 + (number-3) * 20 ;
        else
            height = 60;
        end
        string = ['width="40.0", height="' num2str(height) '", fixedsize=true];\n'];
    end

    function string = blockwidth(number, blocktype)
        % Get dimensions for an arbitrary block for the dotfile graph
        if number > 2
            height = 31 + (number-2) * 15 ;
        else
            height = 31;
        end
        if strcmp(blocktype, 'Bus Creator') ...
            || strcmp(blocktype, 'Bus Selector') ...
            ||strcmp(blocktype, 'Mux') ...
            || strcmp(blocktype, 'Demux')
            width = 9.0;
        else
            width = 30.0;
        end
        string = ['width="' num2str(width) '", height="' num2str(height) '", fixedsize=true];\n'];
    end

    function [newblockname, replaceMap] = replaceItems(blockname, replaceMap)
        % Get new blocknames by replacing unsupported characters with other
        % strings and update the replaceMap which defines the replacements
        replacePattern = '[^\w]|^[0-9]';
        items2Replace = regexp(blockname, replacePattern, 'match');
        for i = 1:length(items2Replace)
            replaceStr = ['badcharacterreplacement' dec2bin(items2Replace{i}, 8)];
            blockname = strrep(blockname, items2Replace{i}, replaceStr);
            replaceMap(replaceStr) = items2Replace{i};
        end
        newblockname = blockname;
    end

    portwidth = 'width="30.0", height="14.0", fixedsize=true];\n';
    dotfile = 'digraph {\n\tgraph [rankdir=LR, ranksep="100.0", nodesep="40.0"];\n';
    dotfile = [dotfile '\tnode [shape=record];\n'];
    replacementMap = containers.Map();
    Blocks = find_system(name, 'LookUnderMasks', 'all', 'SearchDepth',1);
    Blocks = setdiff(Blocks, name);

    % Iterate through blocks in address
    for n = 1:length(Blocks)
        BlockType = get_param(Blocks{n}, 'BlockType');
        Ports = get_param(Blocks{n}, 'Ports');

        % dotfile notations for different block types
        switch BlockType

            case 'SubSystem'
                % dotfile notation for subsystem by finding number of inputs and outputs
                inputnum = Ports(1) + Ports(3) + Ports(4) + Ports(8);
                outputnum = Ports(2);
                blockname = get_param(Blocks{n}, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(blockname, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    blockname = strrep(blockname, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                dotfile = [dotfile blockname '[label="{{'];
                for z = 1:inputnum
                    if z == inputnum
                        dotfile = [dotfile '<i' num2str(z) '>' num2str(z)];
                    else
                        dotfile = [dotfile '<i' num2str(z) '>' num2str(z) '|'];
                    end
                end
                dotfile = [dotfile '}|' blockname '|{'];
                for y = 1:outputnum
                    if y == outputnum
                        dotfile = [dotfile '<o' num2str(y) '>' num2str(y)];
                    else
                        dotfile = [dotfile '<o' num2str(y) '>' num2str(y) '|'];
                    end
                end
                c = max([inputnum outputnum]) ;
                dotfile = [dotfile '}}", ' subwidth(c)];

            case 'Inport'
                % Add text to the dotfile to represent the block
                blockname = get_param(Blocks{n}, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(blockname, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    blockname = strrep(blockname, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                dotfile = [dotfile blockname];
                dotfile = [dotfile ' [label="{{<i1>1}|' blockname '|{<o1>1}}", ' portwidth];

            case 'Outport'
                % Add text to the dotfile to represent the block
                blockname = get_param(Blocks{n}, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(blockname, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    blockname = strrep(blockname, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                dotfile = [dotfile blockname];
                dotfile = [dotfile ' [label="{{<i1>1}|' blockname '|{<o1>1}}", ' portwidth];

            otherwise
                % Add text to the dotfile to represent the block along
                % with its ports and the relative positions of the ports so
                % this information can be used
                blockname = get_param(Blocks{n}, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(blockname, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    blockname = strrep(blockname, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                dotfile = [dotfile blockname ' [label="{'];
                inputnum = Ports(1);
                outputnum = Ports(2);
                if inputnum ~= 0
                    dotfile = [dotfile '{'];
                    for x = 1:inputnum
                         if x == inputnum
                            dotfile = [dotfile '<i' num2str(x) '>' num2str(x)];
                        else
                            dotfile = [dotfile '<i' num2str(x) '>' num2str(x) '|'];
                        end
                    end
                    dotfile = [dotfile '}|'];
                end
                dotfile = [dotfile blockname];
                if outputnum ~= 0
                    dotfile = [dotfile '|{'];
                    for w = 1:outputnum
                        if w == outputnum
                            dotfile = [dotfile '<o' num2str(w) '>' num2str(w)];
                        else
                            dotfile = [dotfile '<o' num2str(w) '>' num2str(w) '|'];
                        end
                    end
                    dotfile = [dotfile '}'];
                end
                blocktype = get_param(Blocks{n}, 'BlockType');
                c = max([inputnum outputnum]) ;
                dotfile = [dotfile '}", ' blockwidth(c, blocktype)];

        end
    end

    % dotfile notations for connections
    for n = 1:length(Blocks)
        linesH = get_param(Blocks{n}, 'LineHandles');
        if ~isempty(linesH.Inport)
            for m = 1:length(linesH.Inport)
            % Find source port number and source block name
                src = get_param(linesH.Inport(m), 'SrcBlockHandle');
                srcName = get_param(src, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(srcName, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    srcName = strrep(srcName, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                srcportHandle = get_param(linesH.Inport(m), 'SrcPortHandle');
                srcport = get_param(linesH.Inport(m), 'SrcPort');
                srcportParent = get_param(srcportHandle, 'Parent');
                srcpHandles = get_param(srcportParent, 'portHandles');
                tol = 1e-6;
                if srcpHandles.Outport
                    srcoutport = srcpHandles.Outport;
                    srcport = find(abs(srcoutport- srcportHandle)<tol);
                elseif srcport
                else
                    srcport = 1;
                end
                srcPortinfo = get_param(src, 'Ports');
                srcinputnum = srcPortinfo(1);
                srcoutputnum = srcPortinfo(2);
                % Find destination block and port
                dest = get_param(linesH.Inport(m), 'DstBlockHandle');
                destName = get_param(dest, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(destName, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    destName = strrep(destName, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                destportHandle = get_param(linesH.Inport(m), 'DstPortHandle');
                destportParent = get_param(destportHandle, 'Parent');
                destpHandles = get_param(destportParent, 'portHandles');
                destport = get_param(linesH.Inport(m), 'DstPort');
                if destpHandles.Inport
                    destinport = destpHandles.Inport;
                    destport = find(abs(destinport-destportHandle)<tol);
                elseif destport
                else
                    destport = 1;
                end
                destPortinfo = get_param(dest, 'Ports');
                destinputnum = destPortinfo(1);
                destoutputnum = destPortinfo(2);
                if srcoutputnum ~= 0

                    dotfile = [dotfile srcName ':o' num2str(srcport)];
                    if destinputnum ~= 0
                        dotfile = [dotfile ' -> ' destName ':i' num2str(destport) sprintf('\n')];
                    else
                        dotfile = [dotfile ' -> ' destName sprintf('\n')];
                    end
                else
                    dotfile = [dotfile srcName];
                    if destinputnum ~= 0
                        dotfile = [dotfile ' -> ' destName ':i' num2str(destport) sprintf('\n')];
                    else
                        dotfile = [dotfile ' -> ' destName sprintf('\n')];
                    end
                end
            end
        end
        % Same as above but for trigger
        if ~isempty(linesH.Ifaction)
            for m = 1:length(linesH.Ifaction)
                if strcmp(get_param(linesH.Ifaction(m), 'type'), 'port')
                    ifactionLine = get_param(linesH.Ifaction(m), 'line');
                else
                    ifactionLine = linesH.Ifaction(m);
                end

                % Find source port number and source block name
                src = get_param(ifactionLine, 'SrcBlockHandle');
                srcName = get_param(src, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(srcName, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    srcName = strrep(srcName, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                srcportHandle = get_param(ifactionLine, 'SrcPortHandle');
                srcport = get_param(ifactionLine, 'SrcPort');
                srcportParent = get_param(srcportHandle, 'Parent');
                srcpHandles = get_param(srcportParent, 'portHandles');
                tol = 1e-6;
                if srcpHandles.Outport
                    srcoutport = srcpHandles.Outport;
                    srcport = find(abs(srcoutport- srcportHandle)<tol);
                elseif srcport
                else
                    srcport = 1;
                end
                srcPortinfo = get_param(src, 'Ports');
                srcinputnum = srcPortinfo(1);
                srcoutputnum = srcPortinfo(2);

                % Find destination block and port
                dest = get_param(ifactionLine, 'DstBlockHandle');
                destName = get_param(dest, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(destName, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    destName = strrep(destName, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                destportHandle = get_param(ifactionLine, 'DstPortHandle');
                destportParent = get_param(destportHandle, 'Parent');
                destpHandles = get_param(destportParent, 'portHandles');
                destport = get_param(ifactionLine, 'DstPort');
                if destpHandles.Ifaction
                    destinport = destpHandles.Ifaction;
                    destport = find(abs(destinport-destportHandle)<tol);
                elseif destport
                else
                    destport = 1;
                end
                destPortinfo = get_param(dest, 'Ports');
                destinputnum = destPortinfo(1);
                destoutputnum = destPortinfo(2);
                if srcoutputnum ~= 0

                    dotfile = [dotfile srcName ':o' num2str(srcport)];
                    if destinputnum ~= 0
                        dotfile = [dotfile ' -> ' destName ':i' num2str(destport) sprintf('\n')];
                    else
                        dotfile = [dotfile ' -> ' destName sprintf('\n')];
                    end
                else
                    dotfile = [dotfile srcName];
                    if destinputnum ~= 0
                        dotfile = [dotfile ' -> ' destName ':i' num2str(destport) sprintf('\n')];
                    else
                        dotfile = [dotfile ' -> ' destName sprintf('\n')];
                    end
                end
            end
        end
    end

    % Create edges between gotos and froms so the final graph will place
    % them closer to each other
    Gotos = find_system(name, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'Goto');%, 'TagVisibility', 'local');
    GotosLength = length(Gotos);
    % When a local goto is found then assume the Goto and From is connected
    for w = 1:GotosLength
        GotoTag = get_param(Gotos{w}, 'Gototag');
        Froms = find_system(name, 'LookUnderMasks', 'all', 'BlockType', 'From', 'Gototag', GotoTag);
        GotoName = get_param(Gotos{w}, 'Name');
        [GotoName, replacementMap] = replaceItems(GotoName, replacementMap);
        Fromslength = length(Froms);
        for h = 1:Fromslength
            FromName = get_param(Froms{h}, 'Name');
            [FromName, replacementMap] = replaceItems(FromName, replacementMap);
            dotfile = [dotfile GotoName '->' FromName sprintf('\n') ];
        end
    end

    % Same as above, but for Data Stores
    Writes = find_system(name, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'BlockType', 'DataStoreWrite');
    WritesLength = length(Writes);
    for w = 1:WritesLength
        DataStoreName = get_param(Writes{w}, 'DataStoreName');
        Reads = find_system(name, 'LookUnderMasks', 'all', 'BlockType', 'DataStoreRead', 'DataStoreName', DataStoreName);
        WriteName = get_param(Writes{w}, 'Name');
        [WriteName, replacementMap] = replaceItems(WriteName, replacementMap);
        Readslength = length(Reads);
        for h = 1:Readslength
            ReadName = get_param(Reads{h}, 'Name');
            [ReadName, replacementMap] = replaceItems(ReadName, replacementMap);
            dotfile = [dotfile WriteName '->' ReadName sprintf('\n') ];
        end
    end

    dotfile = [dotfile '}'];
    fullname = name;
    pattern = '[^\w]|^[0-9]';
    itemsToReplace = regexp(fullname, pattern, 'match');
    for item = 1:length(itemsToReplace)
        fullname = strrep(fullname, itemsToReplace{item}, '');
    end
    thefilename = [fullname '.dot'];
    fid = fopen(thefilename, 'w');
    fprintf(fid,dotfile);
    fclose(fid);
end
