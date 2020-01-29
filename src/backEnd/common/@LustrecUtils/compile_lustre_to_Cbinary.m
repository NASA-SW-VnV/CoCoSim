%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% compile_lustre_to_Cbinary
function err = compile_lustre_to_Cbinary(lus_file_path, ...
        node_name, ...
        output_dir, ...
        LUSTREC,...
        LUSTREC_OPTS, ...
        LUCTREC_INCLUDE_DIR)
    if nargin < 4
        tools_config;
        err = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
        if err
            msg = sprintf('Binary "%s" and directory "%s" not found ',LUSTREC, LUCTREC_INCLUDE_DIR);
            display_msg(msg, MsgType.ERROR, 'generate_lusi', '');
            return;
        end
    end
    [~, file_name, ~] = fileparts(lus_file_path);

    binary_name = fullfile(output_dir,...
        strcat(file_name,'_', node_name));
    % generate C code
    if BUtils.isLastModified(lus_file_path, binary_name)
        err = 0;
        display_msg(['file ' binary_name ' has been already generated.'],...
            MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        return;
    end
    %-algebraic-loop-solve should be added
    command = sprintf('%s %s -I "%s" -d "%s" -node %s "%s"',...
        LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR, output_dir, node_name, lus_file_path);
    msg = sprintf('LUSTREC_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
    [err, lustre_out] = system(command);
    if err
        display_msg(msg, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        msg = sprintf('lustrec failed for model "%s"',lus_file_path);
        display_msg(msg, MsgType.ERROR, 'compile_lustre_to_Cbinary', '');
        display_msg(msg, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        display_msg(lustre_out, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        err = 1;
        return
    end
    OldPwd = pwd;

    % generate C binary
    cd(output_dir);
    makefile_name = fullfile(output_dir,strcat(file_name,'.makefile'));
    msg = sprintf('start compiling model "%s"\n',file_name);
    display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
    
    GCC_FLAGS = 'gcc -O0 -Wno-all -fbracket-depth=10000';
    makefile_OPTS = sprintf('BINNAME="%s" GCC="%s"', binary_name, GCC_FLAGS);
    command = sprintf('make %s -f "%s"',makefile_OPTS, makefile_name);
    msg = sprintf('MAKE_LUSTREC_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
    [err, make_out] = system(command);
    
    if MatlabUtils.contains(make_out, 'unrecognized command line option ‘-fbracket-depth')
        GCC_FLAGS = 'gcc -O0 -Wno-all ';
        makefile_OPTS = sprintf('BINNAME="%s" GCC="%s"', binary_name, GCC_FLAGS);
        command = sprintf('make %s -f "%s"',makefile_OPTS, makefile_name);
        msg = sprintf('MAKE_LUSTREC_COMMAND : %s\n',command);
        display_msg(msg, MsgType.INFO, 'compile_lustre_to_Cbinary', '');
        [err, make_out] = system(command);
    end
    if err
        msg = sprintf('Compilation failed for model "%s" ',file_name);
        display_msg(msg, MsgType.ERROR, 'compile_lustre_to_Cbinary', '');
        display_msg(msg, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        display_msg(make_out, MsgType.DEBUG, 'compile_lustre_to_Cbinary', '');
        err = 1;
        cd(OldPwd);
        return
    end

end
