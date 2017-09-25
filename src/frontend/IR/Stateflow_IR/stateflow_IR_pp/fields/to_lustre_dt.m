function [ new_ir ] = to_lustre_dt( new_ir )
%TO_LUSTRE_DT change simulink datatypes to lustre datatypes
for i=1:numel(new_ir.data)
    new_ir.data(i).datatype = SFIRUtils.to_lustre_dt(new_ir.data(i).datatype);
    new_ir.data(i).initial_value = SFIRUtils.default_InitialValue(new_ir.data(i).initial_value, new_ir.data(i).datatype);
end
for i=1:numel(new_ir.sffunctions)
    new_ir.sffunctions(i) = to_lustre_dt( new_ir.sffunctions(i) );
end
end

