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

function [seal_file, status] = generateLustrevSealFile(lus_full_path, output_dir, main_node, LUSTREV, LUCTREC_INCLUDE_DIR)
    [~, lus_file_name, ~] = fileparts(lus_full_path);
    seal_file = '';
    if nargin < 5 || BUtils.check_files_exist(LUSTREV, LUCTREC_INCLUDE_DIR)
        tools_config;
        status = BUtils.check_files_exist(LUSTREV);
        if status
            msg = 'LUSTRET not found, please configure tools_config file under tools folder';
            display_msg(msg, MsgType.ERROR, 'generateLustrevSealFile', '');
            return;
        end
    end
    z3librc = fullfile(LUCTREC_INCLUDE_DIR, 'z3librc');
    command = sprintf('source %s; %s -I %s -seal -seal-export lustre -d %s -node %s  %s',...
        z3librc, LUSTREV, LUCTREC_INCLUDE_DIR, output_dir, main_node, lus_full_path);
    msg = sprintf('LUSTREV_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'generateLustrevSealFile', '');
    [status, lustrev_out] = system(command);
    if status
        msg = sprintf('lustrev failed for model "%s"',lus_file_name);
        display_msg(msg, MsgType.ERROR, 'generateLustrevSealFile', '');
        display_msg(msg, MsgType.DEBUG, 'generateLustrevSealFile', '');
        display_msg(lustrev_out, MsgType.DEBUG, 'generateLustrevSealFile', '');
        return
    end
    seal_name = strcat( lus_file_name, '_seal.lus');
    seal_file = fullfile(output_dir,seal_name);
    if ~exist(seal_file, 'file')
        display_msg(['No mcdc file has been found in ' output_dir ' with name ' ...
            seal_name], MsgType.ERROR, 'generateLustrevSealFile', '');
        return;
    end
    
end
