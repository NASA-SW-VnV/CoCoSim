function [ new_ir ] = to_lustre_dt( new_ir )
%TO_LUSTRE_DT change simulink datatypes to lustre datatypes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:numel(new_ir.data)
    new_ir.data(i).datatype = SFIRPPUtils.to_lustre_dt(new_ir.data(i).datatype);
    new_ir.data(i).initial_value = SFIRPPUtils.default_InitialValue(new_ir.data(i).initial_value, new_ir.data(i).datatype);
end
for i=1:numel(new_ir.sffunctions)
    new_ir.sffunctions(i) = to_lustre_dt( new_ir.sffunctions(i) );
end
end

