function blks = find_blocks(ss, varargin)
    %% find_system: look for blocks inside a struct using parameters such as BlcokType, MaskType.
    % e.g blks = Block_To_Lustre.find_blocks(ss, 'BlockType', 'UnitDelay', 'StateName', 'X')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    import nasa_toLustre.frontEnd.Block_To_Lustre
    blks = {};
    doesMatch = true;
    for i=1:2:numel(varargin)
        if ~(isfield(ss, varargin{i}) && isequal(ss.BlockType, varargin{i+1}))
            doesMatch = false;
            break;
        end
    end
    if doesMatch
        blks{1} = ss;
    end
    if isfield(ss, 'Content') && ~isempty(ss.Content)
        field_names = fieldnames(ss.Content);
        for i=1:numel(field_names)
            blks_i = Block_To_Lustre.find_blocks(ss.Content.(field_names{i}), varargin{:});
            blks = [blks, blks_i];
        end
    end

end


