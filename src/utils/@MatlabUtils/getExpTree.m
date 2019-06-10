%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function tree = getExpTree(exp)
    em2json =  cocosim.matlab2IR.EM2JSON;
    IR_string = em2json.StringToIR(exp);
    IR = json_decode(char(IR_string));
    tree = IR.statements(1);
end
