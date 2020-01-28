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
 

%% run Zustre or kind2 on verification file
function [answer, IN_struct, time_max] = run_verif(...
        verif_lus_path,...
        inports, ...
        output_dir,...
        node_name,...
        Backend)
    IN_struct = [];
    time_max = 0;
    answer = '';
    if nargin < 1
        error('Missing arguments to function call: LustrecUtils.run_verif')
    end
    [file_dir, file_name, ~] = fileparts(verif_lus_path);
    if nargin < 3 || isempty(output_dir)
        output_dir = file_dir;
    end
    if nargin < 4 || isempty(node_name)
        node_name = 'top';
    end
    if nargin < 5 || isempty(Backend)
        Backend = 'KIND2';
    end
    timeout = '600';
    cd(output_dir);
    tools_config;

    if strcmp(Backend, 'ZUSTRE') || strcmp(Backend, 'Z')
        status = BUtils.check_files_exist(ZUSTRE);
        if status
            return;
        end
        command = sprintf('%s "%s" --node %s --xml  --matlab --timeout %s --save ',...
            ZUSTRE, verif_lus_path, node_name, timeout);
        display_msg(['ZUSTRE_COMMAND ' command],...
            MsgType.DEBUG,...
            'LustrecUtils.run_verif',...
            '');

    elseif strcmp(Backend, 'KIND2') || strcmp(Backend, 'K')
        status = BUtils.check_files_exist(KIND2, Z3);
        if status
            return;
        end
        command = sprintf('%s --z3_bin %s -xml --timeout %s --lus_main %s "%s"',...
            KIND2, Z3, timeout, node_name, verif_lus_path);
        display_msg(['KIND2_COMMAND ' command],...
            MsgType.DEBUG, 'LustrecUtils.run_verif', '');

    end
    [~, solver_output] = system(command);
    display_msg(...
        solver_output,...
        MsgType.DEBUG,...
        'LustrecUtils.run_verif',...
        '');
    [answer, CEX_XML] = ...
        LustrecUtils.extract_answer(...
        solver_output,...
        Backend,  file_name, node_name,  output_dir);
    if strcmp(answer, 'UNSAFE') && ~isempty(CEX_XML)
        [IN_struct, time_max] =...
            LustrecUtils.cexTostruct(CEX_XML, node_name, inports);
    end

end

