function removeBlocksLinkedToMe(bHandle, removeMe)
    portHandles = get_param(bHandle, 'PortHandles');
    for i=1:length(portHandles.Inport)
        line = get_param(portHandles.Inport(i), 'line');
        if line > 0
            src = get_param(line, 'SrcBlockHandle');
            delete_line(line);
            SLXUtils.removeBlocksLinkedToMe(src, true);
        end
    end
    if removeMe
        delete_block(bHandle);
    end
end