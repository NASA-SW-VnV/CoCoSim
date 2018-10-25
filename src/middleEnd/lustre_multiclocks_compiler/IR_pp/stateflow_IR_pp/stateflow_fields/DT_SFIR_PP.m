function [ new_ir, status ] = DT_SFIR_PP( new_ir )
    %DT_SFIR_PP change simulink datatypes to lustre datatypes
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    status = 0;
    for i=1:numel(new_ir.Data)
        [ Lustre_type, zero ] = SLX2LusUtils.get_lustre_dt( new_ir.Data{i}.CompiledType);
        new_ir.Data{i}.LusDatatype = Lustre_type;
        if isequal(new_ir.Data{i}.Scope, 'Parameter')
            new_ir.Data{i}.InitialValue = new_ir.Data{i}.Name;
        elseif strcmp(new_ir.Data{i}.InitialValue, '')
            new_ir.Data{i}.InitialValue = num2str(zero.getValue());
        end
    end
    if isfield(new_ir, 'GraphicalFunctions')
        for i=1:numel(new_ir.GraphicalFunctions)
            new_ir.GraphicalFunctions{i} = DT_SFIR_PP( new_ir.GraphicalFunctions{i} );
        end
    end
end

