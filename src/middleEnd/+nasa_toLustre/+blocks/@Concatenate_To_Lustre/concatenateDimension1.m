function [codes] = concatenateDimension1(inputs, outputs,in_matrix_dimension)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    sizeD1 = 0;
    for i=1:numel(in_matrix_dimension)
        sizeD1 = sizeD1 + in_matrix_dimension{i}.dims(1);
    end
    outMatSize = in_matrix_dimension{1}.dims;
    outMatSize(1) = sizeD1;
    cumuRow = zeros(1,7);  % seven Ds
    cumu = 0;
    for i=1:numel(in_matrix_dimension)
        cumuRow(i) = cumu + in_matrix_dimension{i}.dims(1);
        cumu = cumu + in_matrix_dimension{i}.dims(1);
    end
    codes = cell(1, numel(outputs));
    for i=1:numel(outputs)
        [d1, d2,~,~,~,~,~ ] = ind2sub(outMatSize,i);   % 7 dims max
        rowCounted = 0;
        inputPortIndex = 0;
        for j=1:7
            if d1 <= cumuRow(j)
                inputPortIndex = j;
                if j~= 1
                    rowCounted = cumuRow(j-1);
                end
                break;
            end
        end
        curD1 = d1-rowCounted;
        curMatSize = in_matrix_dimension{inputPortIndex}.dims;
        inputIndex = sub2ind(curMatSize,curD1,d2);
        codes{i} = LustreEq(outputs{i},...
            inputs{inputPortIndex}{inputIndex});
    end
end
