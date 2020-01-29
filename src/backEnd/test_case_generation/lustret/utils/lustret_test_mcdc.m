function [ T ] = lustret_test_mcdc( lus_full_path, node_name, output_dir)
    %lustret_test_mcdc generates unit tests of Lustre nodes based on MC/DC
    %coverage.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

    T = [];
    if nargin < 2
        print_help_messsage();
        return;
    end



    %% generate MC/DC conditions

    mcdc_file = LustrecUtils.generate_MCDCLustreFile(lus_full_path, output_dir);
    new_mcdc_file = LustrecUtils.adapt_lustre_file(mcdc_file, 'Kind2');

    %% Use model checker to find mcdc CEX if exists
    [~, T] = Kind2Utils2.extractKind2CEX(new_mcdc_file, output_dir, node_name, ...
        ' --slice_nodes false --check_subproperties true ');



    end

    function print_help_messsage()
    msg = 'LUSTRET_TEST_MCDC is generating test cases based on MC/DC in Lustre code\n';
    msg = [msg, '\n   Usage: \n '];
    msg = [msg, '\n     lustret_test_mcdc( lus_full_path, output_dir ) \n\n '];
    msg = [msg, '\t     lus_full_path: is the full path of the lustre file that correspond to the Simulink model. \n'];
    msg = [msg, '\t     output_dir: is the full path of the output directory where to produce temporal files. \n'];

    cprintf('blue', msg);
end