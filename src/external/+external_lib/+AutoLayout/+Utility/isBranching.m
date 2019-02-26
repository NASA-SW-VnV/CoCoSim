function b = isBranching(lh)
% ISBRANCHING Determines if given line is a branching line.
%
%   Input:
%       lh  Line handle
%
%   Output:
%       b   Logical. True if line is branching, else false.

    srcs = get_param(lh, 'SrcPortHandle');
    dsts = get_param(lh, 'DstPortHandle');

    assert(length(srcs) <= 1, 'Error unexpected number of sources for line.')
    b = length(dsts) > 1;
end