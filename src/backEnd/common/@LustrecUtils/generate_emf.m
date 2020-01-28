%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
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
 
%%
function [emf_path, status] = ...
        generate_emf(lus_file_path, output_dir, ...
        LUSTREC,...
        LUSTREC_OPTS,...
        LUCTREC_INCLUDE_DIR)
    if nargin < 4
        tools_config;
        status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
        if status
            err = sprintf('Binary "%s" and directory "%s" not found ',LUSTREC, LUCTREC_INCLUDE_DIR);
            display_msg(err, MsgType.ERROR, 'generate_lusi', '');
            return;
        end
    end
    [lus_dir, lus_fname, ~] = fileparts(lus_file_path);
    if nargin < 2 || isempty(output_dir)
        output_dir = fullfile(lus_dir, 'cocosim_tmp', lus_fname);
    end

    if ~exist(output_dir, 'dir'); mkdir(output_dir); end
    emf_path = fullfile(output_dir,strcat(lus_fname, '.json'));
    if BUtils.isLastModified(lus_file_path, emf_path)
        status = 0;
        msg = sprintf('emf file "%s" already generated. It will be used.\n',emf_path);
        display_msg(msg, MsgType.DEBUG, 'generate_emf', '');
        return;
    end
    msg = sprintf('generating emf "%s"\n',lus_file_path);
    display_msg(msg, MsgType.INFO, 'generate_emf', '');
    command = sprintf('%s %s -I "%s" -d "%s"  -emf  "%s"',...
        LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR, output_dir, lus_file_path);
    msg = sprintf('EMF_LUSTREC_COMMAND : %s\n',command);
    display_msg(msg, MsgType.INFO, 'generate_emf', '');
    [status, emf_out] = system(command);
    if status
        err = sprintf('generation of emf failed for file "%s" ',lus_fname);
        display_msg(err, MsgType.WARNING, 'generate_emf', '');
        LustrecUtils.parseLustrecErrorMessage(emf_out, MsgType.WARNING);
        display_msg(err, MsgType.DEBUG, 'generate_emf', '');
        display_msg(emf_out, MsgType.DEBUG, 'generate_emf', '');

        return
    end

end

