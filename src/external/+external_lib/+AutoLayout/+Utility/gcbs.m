function sels = gcbs
    %sels = gcbs
    %returns a cell array of all currently selected blocks
    %limited to the subsystem established by GCB.
    %C. Hecker/11Dec06
    ssys = get_param(gcb, 'parent');
    nBlks = find_system(ssys,'SearchDepth',1, 'LookUnderMasks', 'all', 'FollowLinks', 'on');
    nBlks = nBlks(2:end); %strip off parent system name
    idx = strcmp(get_param(nBlks, 'selected'), 'on');
    sels = nBlks(idx);
end

