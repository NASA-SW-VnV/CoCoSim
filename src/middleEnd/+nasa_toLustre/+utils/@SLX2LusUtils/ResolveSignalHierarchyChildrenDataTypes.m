function lus_dt = ResolveSignalHierarchyChildrenDataTypes(blk)
%This function attempts to resolve types of elements in unhandled bus
%signals in the SignalHierarchyLusDT. The types of the signal elements are
%resolved by recursively backtracing each element's origin outport, and
%subsequently the origin's type.
    try
        blkPath = blk.Path;       
        blkType = blk.BlockType;
    
        lus_dt={};
        if (strcmp(blkType,'Inport') || strcmp(blkType,'Outport'))
            blkParent = get_param(blkPath,'Parent');
            if (isempty(blkParent))
                blkParent = blkPath;
            end
            blkInports = find_system(blkParent,'LookUnderMasks','all','FollowLinks','On','SearchDepth',1,'BlockType','Inport');
            blkEnablePorts = find_system(blkParent,'LookUnderMasks','all','FollowLinks','On','SearchDepth',1,'BlockType','EnablePort');
            blkOutports = find_system(blkParent,'LookUnderMasks','all','FollowLinks','On','SearchDepth',1,'BlockType','Outport');
            blkPorts = [blkInports; blkEnablePorts; blkOutports];
            portIndex = find(strcmp(blkPorts, blkPath));
            lus_dt = resolveViaBackTracing(blkParent, portIndex);
        else
            blockOutports = find_system(blk.Path,'SearchDepth', 1,'BlockType','Outport');      
            for i=1:numel(blockOutports)
                lus_dt = [lus_dt, resolveViaBackTracing(blockOutports{i})];
            end
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'ResolveSignalHierarchyChildrenDataTypes', '');        
        display_msg(me.message, MsgType.ERROR, 'ResolveSignalHierarchyChildrenDataTypes', '');        
    end
end

function lus_dt = resolveViaBackTracing(startingBlock, portIndex)        
    try
        parentPortConn = get_param(startingBlock,'PortConnectivity');
        portSrcBlock = {};
        if (strcmp(get_param(startingBlock, 'BlockType'), 'SubSystem'))
            portSrcBlock = {parentPortConn(portIndex).SrcBlock};
        else
            Allfields = arrayfun(@(x) struct2cell(x), parentPortConn, 'UniformOutput', false);
            SrcBlockList = cellfun(@(x) squeeze(x(3,:,:)), Allfields,  'UniformOutput', false);
            if iscell(SrcBlockList{1})
                listElems = cat(1,SrcBlockList{:});
                portSrcBlock = listElems(~cellfun('isempty',listElems));
            else
                portSrcBlock = SrcBlockList;
            end
        end
    
        srcBlockName = cellfun(@(x) getfullname(x), portSrcBlock, 'UniformOutput', false);     
        srcBlockPorts={};
        actualPorts={};
        srcPortDataType = {};
        srcBlockType = get_param(srcBlockName,'BlockType');

        for i=1:numel(srcBlockType)
            if (strcmp(srcBlockType{i}, 'SubSystem') || strcmp(srcBlockType{i}, 'S-Function') || strcmp(srcBlockType{i}, 'UnitDelay'))
                srcBlockPortConn = get_param(srcBlockName{i}, 'PortConnectivity');
                srcBlockDstBlocks = arrayfun(@(x) x.DstBlock,srcBlockPortConn,'UniformOutput',false);                
                
                srcBlockDstBlocks = cellfun(@(x) strcmp(getfullname(x),startingBlock), srcBlockDstBlocks,'UniformOutput',false);
                srcBlockDstBlocks = cellfun(@(x) ismember(1, x), srcBlockDstBlocks, 'UniformOutput',1);
                srcPortIndex = find(srcBlockDstBlocks);
                
                srcBlockPorts = [];
                if (strcmp(srcBlockType{i}, 'SubSystem'))
                    srcBlkInports = find_system(srcBlockName{i},'LookUnderMasks','all','FollowLinks','On','SearchDepth',1,'BlockType','Inport');
                    srcBlkEnablePorts = find_system(srcBlockName{i},'LookUnderMasks','all','FollowLinks','On','SearchDepth',1,'BlockType','EnablePort');
                    srcBlkOutports = find_system(srcBlockName{i},'LookUnderMasks','all','FollowLinks','On','SearchDepth',1,'BlockType','Outport');
                    srcBlockPorts = [srcBlkInports; srcBlkEnablePorts; srcBlkOutports];
                elseif (strcmp(srcBlockType{i}, 'UnitDelay'))
                    srcBlockPorts = {srcBlockName{i}; srcBlockName{i}};
                else
                    %Case of S-Function
                    srcBlkPortHandles = get_param(srcBlockName{i}, 'PortHandles');
                    srcBlockPorts = [arrayfun(@(x) x, srcBlkPortHandles.Inport', 'UniformOutput',false);...
                        arrayfun(@(x) x, srcBlkPortHandles.Outport', 'UniformOutput',false)];
                end
                actualPorts{end+1} = srcBlockPorts{srcPortIndex};
                        
                subSysPortTypes = coco_nasa_utils.SLXUtils.getCompiledParam(srcBlockName{i}, 'CompiledPortDataTypes');
                subSysPortTypes = cat(2, subSysPortTypes.Inport, subSysPortTypes.Enable, subSysPortTypes.Outport);
                srcPortDataType{end+1} = subSysPortTypes{srcPortIndex};
            else
                actualPorts{end+1} = srcBlockName{i};
                srcPortDataType{end+1} = get_param(srcBlockName{i}, 'OutDataTypeStr');
            end
        end    
    
        lus_dt = {};
    
        if (all(strcmp(srcPortDataType, 'Inherit: auto')) || all(strcmp(srcPortDataType, 'auto')))
            for i=1:numel(actualPorts)
                lus_dt = [lus_dt, resolveViaBackTracing(actualPorts{i})];
            end
        else        
            for i=1:numel(actualPorts)
                dataType = srcPortDataType{i};
                if (strcmp(dataType, 'Inherit: auto') || (strcmp(dataType, 'auto')))
                    lus_dt = [lus_dt, resolveViaBackTracing(actualPorts{i})];
                else
                    %actualPorts here may contain Outport blocks, which don't
                    %have a destination block in their PortConnectivity
                    %parameter.
                    
                    if (strcmp(get_param(actualPorts{i},'BlockType'),'Outport'))
                        actualPortDimensions = coco_nasa_utils.SLXUtils.getCompiledParam(actualPorts{i}, 'CompiledPortDimensions');
                        inportDimensions = prod(actualPortDimensions.Inport,'all');
                        if (inportDimensions > 1)
                            for i=1:inportDimensions
                                lus_dt = [lus_dt, nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(dataType)];
                            end
                        else
                            lus_dt = [lus_dt, nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(dataType)];
                        end
                    elseif (strcmp(get_param(get_param(actualPorts{1},'Parent'),'BlockType'),'S-Function'))
                        lus_dt = coco_nasa_utils.SLXUtils.getCompiledParam(actualPorts{i}, 'CompiledPortDataType');
                    else
                        %I need the port handle here. Get port handles, the figure
                        %out which outport connects to current block
                        portConnectivity = get_param(actualPorts{i},'PortConnectivity');
                        portHandles = get_param(actualPorts{i}, 'PortHandles');
                        
                        dstBlocks = {};
                        if numel(portConnectivity) > 1
                            dstBlocks = arrayfun(@(x) x.DstBlock,portConnectivity,'UniformOutput',false);
                        else
                            dstBlocks = portConnectivity.DstBlock;
                        end
                        portIndex = find(strcmp(getfullname(dstBlocks),startingBlock));
                        
                        inportsAndOutportsCells = {num2cell(portHandles.Inport)'; num2cell(portHandles.Outport)'};
                        combinedInportsAndOutports = cat(1,inportsAndOutportsCells{:});
            
                        portWidth = coco_nasa_utils.SLXUtils.getCompiledParam(combinedInportsAndOutports{portIndex}, 'CompiledPortWidth');
                        for j=1:portWidth
                            lus_dt = [lus_dt, nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(dataType)];
                        end
                    end
                end
            end
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'resolveViaBackTracing', '');        
        display_msg(me.message, MsgType.ERROR, 'resolveViaBackTracing', '');        
    end
end

