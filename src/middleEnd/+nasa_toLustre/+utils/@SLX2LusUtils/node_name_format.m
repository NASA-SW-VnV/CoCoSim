%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Lustre node name from a simulink block name. Here we choose only
%the name of the block concatenated to its handle to be unique
%name.
function node_name = node_name_format(subsys_struct)
    if isempty(strfind(subsys_struct.Path, filesep))
        % main node: should be the same as filename
        node_name = nasa_toLustre.utils.SLX2LusUtils.name_format(subsys_struct.Name);
    else
        handle_str = strrep(sprintf('%.3f', subsys_struct.Handle), '.', '_');
        node_name = sprintf('%s_%s',nasa_toLustre.utils.SLX2LusUtils.name_format(subsys_struct.Name),handle_str );
    end
end

