function SF_DATA_MAP = addArrayData(SF_DATA_MAP, d_list)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    
    for i=1:numel(d_list)
        names = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataName(d_list{i});
        if numel(names) > 1
            try
                [InitialValue, ~, ~] = ...
                    SLXUtils.evalParam(gcs, [], [], d_list{i}.InitialValue);
            catch
                InitialValue = 0;
            end
            for j=1:numel(names)
                d = d_list{i};
                d.Name = names{j};
                d.ArraySize = '1';
                d.CompiledSize = '1';
                if numel(InitialValue) >= j
                    v = InitialValue(j);
                else
                    v = InitialValue(1);
                end
                d.InitialValue = num2str(v);
                d.Scope = 'Array';
                SF_DATA_MAP(names{j}) = d;
            end
        end
    end
end