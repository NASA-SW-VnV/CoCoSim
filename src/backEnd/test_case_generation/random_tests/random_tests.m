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
function [ T,  new_model_name] = random_tests( model_full_path, nb_steps, IMIN, IMAX, exportToWs, mkHarnessMdl )
    %RANDOM_TESTS Summary of this function goes here
    %   Detailed explanation goes here
    T = [];
    new_model_name = '';
    if ~exist(model_full_path, 'file')
        display_msg(['File not foudn: ' model_full_path],...
            MsgType.ERROR, 'random_tests', '');
        return;
    else
        model_full_path = which(model_full_path);
    end
    [model_path, slx_file_name, ~] = fileparts(model_full_path);
    display_msg(['Generating random tests for : ' slx_file_name],...
        MsgType.INFO, 'random_tests', '');
    if ~exist('nb_steps', 'var') || isempty(nb_steps)
        nb_steps = 100;
    end
    if ~exist('IMAX', 'var') || isempty(IMAX)
        IMAX = 100;
    end
    if ~exist('IMIN', 'var') || isempty(IMIN)
        IMIN = -100;
    end
    if ~exist('exportToWs', 'var') || isempty(exportToWs)
        exportToWs = 0;
    end
    if ~exist('mkHarnessMdl', 'var') || isempty(mkHarnessMdl)
        mkHarnessMdl = 0;
    end
    addpath(model_path);
    load_system(model_full_path);
    %% Get model inports informations
    try
        [inports, ~] = coco_nasa_utils.SLXUtils.get_model_inputs_info(model_full_path);
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'random_tests', '');
        display_msg(sprintf('Model information of "%s" cannot be obtained.', model_full_path), MsgType.ERROR, 'random_tests', '');
        return;
    end
    [T, ~, ~] = coco_nasa_utils.SLXUtils.get_random_test(slx_file_name, inports, nb_steps,IMAX, IMIN);
    
    if exportToWs
        assignin('base', strcat(slx_file_name, '_random_tests'), T);
        display_msg(['Generated test suite is saved in workspace under name: ' strcat(slx_file_name, '_random_tests')],...
            MsgType.RESULT, 'random_tests', '');
    end

    if mkHarnessMdl
        output_dir = fullfile(model_path, 'cocosim_output', slx_file_name);
        if ~exist(output_dir, 'dir'), mkdir(output_dir); end
        new_model_name = coco_nasa_utils.SLXUtils.makeharness(T, slx_file_name, output_dir);
    end
end

