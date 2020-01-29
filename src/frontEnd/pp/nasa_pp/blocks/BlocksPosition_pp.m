%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [status, errors_msg] = BlocksPosition_pp( model, depth )
    %BLOCKS_POSITION_PROCES try to improve blocks position for better graphical readability.

    status = 0;
    errors_msg = {};
    
    clear organize
    limitedDepth = true;
    if ~exist('depth', 'var')
        limitedDepth = false;
        depth = 100000;
    end
    %Take the list of all blocks that has no outport so they can be at one
    %level. Blocks such Outports, displays ...
    allBlocks = find_system(model,'LookUnderMasks', 'all', 'SearchDepth', 1);
    levels_map =  [];
    
    try
        % Methode 1: call Auto Layout
        display_msg(...
            sprintf('organizing block "%s" positions. This process may take few seconds.',model),...
            MsgType.INFO, 'BlocksPosition_pp', '');
        external_lib.AutoLayout.AutoLayout(model)
    catch
        % If Method 1 failed: Use my version of Auto Layout.
        for i=2:length(allBlocks)
            try
                DstBlkH = get_param(allBlocks{i}, 'PortHandles');
                if isempty(DstBlkH.Outport)
                    display_msg(...
                        sprintf('organizing block "%s" and its linked blocks',allBlocks{i}),...
                        MsgType.INFO, 'BlocksPosition_pp', '');
                    levels_map = organize(get_param(allBlocks{i}, 'Handle'), 0, levels_map);
                end
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('BlocksPosition pre-process has failed for block %s', allBlocks{i});
                continue;
            end
        end
    end
    
    % call BlocksPosition_pp recursivly on SubSystems inside
    for i=2:length(allBlocks)
        if strcmp(get_param(allBlocks{i}, 'BlockType'),'SubSystem')
            if (~limitedDepth) || (limitedDepth && 0 < depth)
                BlocksPosition_pp( allBlocks{i} , depth - 1);
            end
        end
        
    end
    
end

%%
function levels_map = organize(block_handle, level, levels_map)
    
    
    % this variable save all processed blocks to avoid loops,
    persistent alreadyProcessed;
    
    if isempty(alreadyProcessed)
        alreadyProcessed(1) = block_handle;
    elseif ~ismember(block_handle, alreadyProcessed)
        alreadyProcessed(numel(alreadyProcessed) + 1) = block_handle;
    else
        %disp('***************')
        return;
    end
    if isempty(levels_map)
        levels_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    end
    if ~isKey(levels_map, level)
        if isKey(levels_map, level - 1)
            last_level_pos =  levels_map(level - 1);
            levels_map(level) = [last_level_pos(1) - 200, 50,...
                last_level_pos(1) - 100, 100];
        else
            levels_map(level) = [1000, 50, 1050, 100];
        end
    end
    
    pos = get_param(block_handle, 'Position');
    dx = pos(3) - pos(1);
    dy = pos(4) - pos(2);
    
    current_pos = levels_map(level);
    left = current_pos(3) - dx;
    top = current_pos(2);
    right = current_pos(3);
    bottom = current_pos(2) + dy;
    
    set_param(block_handle, 'Position', [left, top, right, bottom]);
    min_left = min(left, current_pos(1));
    
    levels_map(level) = [min_left, bottom + 50, right, bottom + 100];
    
    portHandles = get_param(block_handle, 'PortHandles');
    srcBlocks = [];
    inports = [ portHandles.Enable, portHandles.Trigger,...
        portHandles.Ifaction, portHandles.Reset, portHandles.Inport];
    for i=1:numel(inports)
        l = get_param(inports(i), 'line');
        if l == -1
            continue;
        end
        src = get_param(l, 'SrcBlockHandle');
        if ismember(src, alreadyProcessed)
            continue;
        end
        if ~ismember(src, srcBlocks)
            srcBlocks(numel(srcBlocks) + 1) = src;
            display_msg(...
                sprintf('organizing block "%s" and its linked blocks',get_param(src, 'Name')),...
                MsgType.INFO, 'organize', '');
            levels_map = organize(src, level + 1, levels_map);
        end
        srcPortHandle = get_param(l, 'SrcPortHandle');
        sourceLine = get_param(srcPortHandle, 'line');
        distinations = get_param(sourceLine, 'DstPortHandle');
        for d=distinations'
            l = get_param(d, 'line');
            try delete(l); catch, end
            add_line(get_param(src, 'Parent'), srcPortHandle, d);
        end
        % reline the line
        
    end
    
end