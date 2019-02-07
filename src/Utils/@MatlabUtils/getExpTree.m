
function tree = getExpTree(exp)
    em2json =  cocosim.matlab2IR.EM2JSON;
    IR_string = em2json.StringToIR(exp);
    IR = json_decode(char(IR_string));
    tree = IR.statements(1);
end
