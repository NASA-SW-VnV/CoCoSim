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
%% run kind2 with arguments
function [status, solver_output] = runKIND2(...
    verif_lus_path,...
    node, ...
    OPTS, KIND2, timeout, timeout_analysis)

    global Z3 YICES2
    status = 0;

    if nargin < 1
        error('Missing arguments to function call: coco_nasa_utils.Kind2Utils.runKIND2')
    end
    %
    
    %
    if ~exist('OPTS', 'var')
        OPTS = '';
    end
    
    CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    if isfield(CoCoSimPreferences, 'kind2SmtSolver') ...
            && strcmp(CoCoSimPreferences.kind2SmtSolver, 'Z3')
        solver = Z3;
        OPTS = sprintf('%s --smt_solver Z3 --z3_bin %s', OPTS, Z3);
    else
        solver = YICES2;
        OPTS = sprintf('%s --smt_solver Yices2 --yices2_bin %s', OPTS, YICES2);
    end
    
    if nargin >= 2 && ~isempty(node)
        OPTS = sprintf('%s --lus_main %s', OPTS, node);
    end
    if nargin >= 7 && ~isempty(timeout_analysis)
        OPTS = sprintf('%s --timeout_analysis %d', OPTS, timeout_analysis);
    end
    %
    if nargin < 4
        tools_config;
        status = coco_nasa_utils.MatlabUtils.check_files_exist(KIND2, solver);
        if status
            display_msg(['KIND2 or Z3/Yices2 not found :' KIND2 ', ' solver],...
                MsgType.DEBUG, 'LustrecUtils.run_verif', '');
            return;
        end
    end
    %
    if ~exist('timeout', 'var') || isempty(timeout)
        CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
        if isfield(CoCoSimPreferences, 'verificationTimeout')
            timeout = num2str(CoCoSimPreferences.verificationTimeout);
        else
            timeout = '120';
        end
    elseif isnumeric(timeout)
        timeout = num2str(timeout);
    end

    command = sprintf('%s -xml  --timeout %s %s "%s"',...
        KIND2, timeout, OPTS,  verif_lus_path);
    display_msg(['KIND2_COMMAND ' command],...
        MsgType.DEBUG, 'coco_nasa_utils.Kind2Utils.run_verif', '');

    [~, solver_output] = system(command, '-echo' );
    display_msg(...
        solver_output,...
        MsgType.DEBUG,...
        'coco_nasa_utils.Kind2Utils.run_verif',...
        '');

end
