function input_block_name = get_input_block_name_from_variable(xRoot, node, var_name, Sim_file_name,new_model_name)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    input_block_name = SLX2Lus_Trace.get_SlxBlockName_from_LusVar_UsingXML(xRoot, node, var_name);
    input_block_name = regexprep(input_block_name,strcat('^',Sim_file_name,'/(\w)'),strcat(new_model_name,'/$1'));
end

