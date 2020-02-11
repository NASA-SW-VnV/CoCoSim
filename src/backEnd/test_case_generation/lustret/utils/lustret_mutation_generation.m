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
function [ err, output_dir] = lustret_mutation_generation( lus_full_path, nb_mutants_max )
    %LUSTRET_TEST_GENERATION Generate test cases based on mutation.
    
    if ~exist('nb_mutants_max', 'var')
        nb_mutants_max = 500;
    end

    err = 0;
    generation_start = tic;
    [file_parent, file_name, ~] = fileparts(lus_full_path);
    node_name = MatlabUtils.fileBase(file_name);
    output_dir = fullfile(file_parent, strcat(file_name,'_mutants'));
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    else
        mutant_path = fullfile(...
            output_dir, ...
            strcat(file_name, '.mutant.n',num2str(nb_mutants_max),'.lus'));
        if BUtils.isLastModified(lus_full_path, mutant_path)
            err = 0;
            display_msg('mutants have been already generated', MsgType.DEBUG, 'Validation', '');
            return;
        end
    end

    tools_config;
    status = BUtils.check_files_exist(LUSTRET, LUCTREC_INCLUDE_DIR);
    if status
        msg = 'LUSTREC not found, please configure tools_config file under tools folder';
        display_msg(msg, MsgType.ERROR, 'lustret_mutation_generation', '');
        err = 1;
        return;
    end



    command = sprintf('%s -I %s -nb-mutants %d -node %s -d %s %s',LUSTRET, LUCTREC_INCLUDE_DIR, nb_mutants_max, node_name, output_dir, lus_full_path);
    msg = sprintf('LUSTRET_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'lustret_mutation_generation', '');
    display_msg('Please Kill me (Ctrl+C) if I am taking long time',...
        MsgType.INFO, 'lustret_mutation_generation', '');
    [status, lustret_out, ~] = external_lib.cmd_timeout.system_timeout(command,7);
    if status
        msg = sprintf('lustret failed for model "%s"',file_name);
        display_msg(msg, MsgType.INFO, 'lustret_mutation_generation', '');
        display_msg(msg, MsgType.ERROR, 'lustret_mutation_generation', '');
        display_msg(msg, MsgType.DEBUG, 'lustret_mutation_generation', '');
        display_msg(lustret_out, MsgType.DEBUG, 'lustret_mutation_generation', '');
        err = 1;
        return
    end


    generation_stop = toc(generation_start);
    fprintf('mutations has been generated in %f seconds\n', generation_stop);
end

