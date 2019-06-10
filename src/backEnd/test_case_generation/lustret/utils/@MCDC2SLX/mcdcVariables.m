%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function variables_names = mcdcVariables(node_struct)
    variables_names = {};
    annotations = node_struct.annots;
    fields = fieldnames(annotations);
    for i=1:numel(fields)
        if ismember('mcdc', annotations.(fields{i}).key) ...
                && ismember('coverage', annotations.(fields{i}).key)
            try
                variables_names{end + 1} = ...
                    annotations.(fields{i}).eexpr.qfexpr{1}.value;
            catch
            end
        end
    end
    
end
