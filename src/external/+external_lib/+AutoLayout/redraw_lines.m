function redraw_lines(sys, varargin)
% REDRAW_LINES Redraw all lines in the system.
%
%   Inputs:
%       sys             Simulink system path name.
%       varargin{1}     Set to 'autorouting' to enable use of varargin{2}.
%       varargin{2}     Type of automatic line routing around other blocks:
%                       'on', 'off', 'smart'. Default is 'off'.
%
%   Outputs:
%       N/A
%
%   Examples:
%       redraw_lines(gcs)
%           Redraws lines in the current system with autorouting off.
%
%       redraw_lines(gcs, 'autorouting', 'on')
%           Redraws lines in the current system with autorouting on.

    % Handle inputs
    if isempty(varargin) || length(varargin) < 2
        autorouting = 'off';
    else
        if isequal(varargin{1}, 'autorouting')
            autorouting = varargin{2};
        end
    end

    allBlocks = get_param(sys, 'Blocks');
    for n = 1:length(allBlocks)
        allBlocks{n} = strrep(allBlocks{n}, '/', '//');
        lineHdls = get_param([sys, '/', allBlocks{n}], 'LineHandles');
        if ~isempty(lineHdls.Inport)
            for m = 1:length(lineHdls.Inport)
                srcport = get_param(lineHdls.Inport(m), 'SrcPortHandle');
                dstport = get_param(lineHdls.Inport(m), 'DstPortHandle');
                % Delete and re-add
                delete_line(lineHdls.Inport(m))
                add_line(sys, srcport, dstport, 'autorouting', autorouting);
            end
        end
    end
end