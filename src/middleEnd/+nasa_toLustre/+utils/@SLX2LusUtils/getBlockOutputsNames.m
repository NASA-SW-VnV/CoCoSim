
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% get block outputs names: inlining dimension
function [names, names_dt] = getBlockOutputsNames(parent, blk, ...
        srcPort, xml_trace)
    % This function return the names of the block
    % outputs.
    % Example : an Inport In with dimension [2, 3] will be
    % translated as : In_1, In_2, In_3, In_4, In_5, In_6.
    % where In_1 = In(1,1), In_2 = In(2,1), In_3 = In(1,2),
    % In_4 = In(2,2), In_5 = In(1,3), In_6 = In(2,3).
    % A block is defined by its outputs, if a block does not
    % have outports, like Outport block, than will be defined by its
    % inports. E.g, Outport Out with width 2 -> Out_1, out_2
    blksNamesDefinedByTheirInports = {'Outport', 'Goto'};
    needToLogTraceability = 0;
    if nargin > 3
        % this function is only called with "xml_trace" variable in
        % Block_To_Lustre classes. 
        needToLogTraceability = 1;
    end
    names = {};
    names_dt = {};
    if isempty(blk) ...
            || (isempty(blk.CompiledPortWidths.Outport) ...
            && isempty(blk.CompiledPortWidths.Inport))
        return;
    end
    % case of block with 'auto' Type, we need to get the inports
    % datatypes.
    if numel(blk.CompiledPortDataTypes.Outport) == 1 ...
            && strcmp(blk.CompiledPortDataTypes.Outport{1}, 'auto') ...
            && ~isempty(blk.CompiledPortWidths.Inport)...
            && ~isequal(blk.BlockType, 'SubSystem') 

        if numel(blk.CompiledPortWidths.Inport) > 1 ...
                && isequal(blk.BlockType, 'BusCreator') 
            % e,g BusCreator DT is defined by all its inputs
            width = blk.CompiledPortWidths.Inport;
        else
            % e,g BusAssignment and other blocks DT are
            % defined by their first input
            width = blk.CompiledPortWidths.Inport(1);
        end
        type = 'Inports';

    elseif isempty(blk.CompiledPortWidths.Outport) ...
            && ismember(blk.BlockType, blksNamesDefinedByTheirInports)
        width = blk.CompiledPortWidths.Inport;
        type = 'Inports';
    else
        width = blk.CompiledPortWidths.Outport;
        type = 'Outports';
    end

