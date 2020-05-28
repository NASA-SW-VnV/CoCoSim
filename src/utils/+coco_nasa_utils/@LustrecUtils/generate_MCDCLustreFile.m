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

function [mcdc_file] = generate_MCDCLustreFile(lus_full_path, output_dir)
    [~, lus_file_name, ~] = fileparts(lus_full_path);
    tools_config;
    status = coco_nasa_utils.MatlabUtils.check_files_exist(LUSTRET);
    if status
        msg = 'LUSTRET not found, please configure tools_config file under tools folder';
        display_msg(msg, MsgType.ERROR, 'generate_MCDCLustreFile', '');
        return;
    end
    command = sprintf('%s -I %s -d %s -mcdc-cond  %s',LUSTRET, LUCTREC_INCLUDE_DIR, output_dir, lus_full_path);
    msg = sprintf('LUSTRET_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'generate_MCDCLustreFile', '');
    [status, lustret_out] = system(command);
    if status
        msg = sprintf('lustret failed for model "%s"',lus_file_name);
        display_msg(msg, MsgType.INFO, 'generate_MCDCLustreFile', '');
        display_msg(msg, MsgType.ERROR, 'generate_MCDCLustreFile', '');
        display_msg(msg, MsgType.DEBUG, 'generate_MCDCLustreFile', '');
        display_msg(lustret_out, MsgType.DEBUG, 'generate_MCDCLustreFile', '');
        return
    end

    mcdc_file = fullfile(output_dir,strcat( lus_file_name, '.mcdc.lus'));
    if ~exist(mcdc_file, 'file')
        display_msg(['No mcdc file has been found in ' output_dir ' with name ' ...
            strcat( lus_file_name, '.mcdc.lus')], MsgType.ERROR, 'generate_MCDCLustreFile', '');
        return;
    end

end
