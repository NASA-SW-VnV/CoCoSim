
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function clocks_list = getRTClocksSTR(blk, main_sampleTime)
    clocks_list = {};
    clocks = blk.CompiledSampleTime;
    if iscell(clocks)
        cell_clocks = clocks;
    else
        cell_clocks{1} = clocks;
    end
    if ~isempty(cell_clocks) % && numel(clocks) > 1 % a subsystem can run on [2,0]
        clocks_list = {};
        for i=1:numel(cell_clocks)
            T = cell_clocks{i};
            if T(1) < 0 || isinf(T(1))
                continue;
            end
            st_n = T(1)/main_sampleTime(1);
            ph_n = T(2)/main_sampleTime(1);
            if ~nasa_toLustre.utils.SLX2LusUtils.isIgnoredSampleTime(st_n, ph_n)
                clocks_list{end+1} = nasa_toLustre.utils.SLX2LusUtils.clockName(st_n, ph_n);
            end
        end
    end
    % order clocks by alphabetic order
    clocks_list = sort(clocks_list);
end


