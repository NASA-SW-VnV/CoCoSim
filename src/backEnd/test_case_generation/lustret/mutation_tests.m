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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ T,  harness_model_name, status] = mutation_tests( model_full_path,...
        exportToWs, mkHarnessMdl, nb_steps, IMIN, IMAX, max_nb_test, min_coverage)
    %mutation_tests Summary of this function goes here
    %   Detailed explanation goes here
    global KIND2 LUSTRET; 
    harness_model_name = '';
    if isempty(KIND2)
        tools_config;
    end
    if ~exist(KIND2,'file')
        errordlg(sprintf('KIND2 model checker is not found in %s. Please set KIND2 path in tools_config.m under tools folder.', KIND2));
        status = 1;
        return;
    end
    status = BUtils.check_files_exist(LUSTRET);
    if status
        msg = 'LUSTRET not found, please configure tools_config file under tools folder';
        errordlg(msg);
        status = 1;
        return;
    end
    
    if ~exist(model_full_path, 'file')
        display_msg(['File not foudn: ' model_full_path],...
            MsgType.ERROR, 'mutation_tests', '');
        status = 1;
        return;
    else
        model_full_path = which(model_full_path);
    end
    [model_path, slx_file_name, ~] = fileparts(model_full_path);
    display_msg(['Generating mutation based tests for : ' slx_file_name],...
        MsgType.INFO, 'mutation_tests', '');
    if ~exist('nb_steps', 'var') || isempty(nb_steps)
        nb_steps = 100;
    end
    if ~exist('IMAX', 'var') || isempty(IMAX)
        IMAX = 100;
    end
    if ~exist('IMIN', 'var') || isempty(IMIN)
        IMIN = -100;
    end
    if ~exist('max_nb_test', 'var') || isempty(max_nb_test)
        max_nb_test = 100;
    end
    if ~exist('min_coverage', 'var') || isempty(min_coverage)
        min_coverage = 95;
    end
    if ~exist('exportToWs', 'var') || isempty(exportToWs)
        exportToWs = 0;
    end
    if ~exist('mkHarnessMdl', 'var') || isempty(mkHarnessMdl)
        mkHarnessMdl = 0;
    end
    addpath(model_path);
    load_system(model_full_path);
    %% Compile model
    [lus_full_path, xml_trace, is_unsupported, ~, ~, pp_model_full_path] = ...
        nasa_toLustre.ToLustre(model_full_path, [], coco_nasa_utils.LusBackendType.LUSTREC);
    if is_unsupported
        display_msg('Model is not supported', MsgType.ERROR, 'validation', '');
        return;
    end
    [output_dir, lus_file_name, ~] = fileparts(lus_full_path);
    node_name = coco_nasa_utils.MatlabUtils.fileBase(lus_file_name);%remove .LUSTREC/.KIND2 from name.
    try
        [ T, ~, status ] = lustret_test_mutation( pp_model_full_path, ...
            lus_full_path, ...
            xml_trace, ...
            node_name,...
            nb_steps,...
            IMIN, ...
            IMAX,...
            'KIND2', ...
            1000, ...
            max_nb_test,...
            min_coverage );
    catch me
        display_msg(['Mutation test generation failed for model ' slx_file_name],...
            MsgType.ERROR, 'mutation_tests', '');
        display_msg(me.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
        return;
    end
    %%
    if exportToWs
        if isempty(T)
            display_msg('No test suite has been generated.', MsgType.RESULT, 'mutation_tests', '');
            return;
        else
            assignin('base', strcat(slx_file_name, '_mutation_tests'), T);
            display_msg(['Generated test suite is saved in workspace under name: ' strcat(slx_file_name, '_mutation_tests')],...
                MsgType.RESULT, 'mutation_tests', '');
        end
    end
    
    %%
    
    if mkHarnessMdl
        if ~exist(output_dir, 'dir'), mkdir(output_dir); end
        harness_model_name = coco_nasa_utils.SLXUtils.makeharness(T, slx_file_name, output_dir, '_mutations');
    end
end

