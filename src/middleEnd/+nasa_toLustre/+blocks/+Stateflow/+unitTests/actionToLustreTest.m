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
function notSupportedActions = actionToLustreTest()
    %ACTIONTOLUSTRETEST is checking if all the following expressions pass
    %through the parser that is used by the compiler.
    

    
    notSupportedActions = {};
    P = fileparts(mfilename('fullpath'));
    mat_file = fullfile(P, 'scripts', 'sfdemosActions.mat');
    if ~exist(mat_file, 'file')
        display_msg(sprintf('File not found: %s', mat_file), ...
            MsgType.ERROR, 'actionToLustreTest', '');
        return;
    end
    M = load(mat_file);
    actions = M.actions;
    conditions = M.conditions;
    
    %add additional Actions here
    additionalActions = {...
        'x++'...
        };
    actions = [actions, additionalActions];
    
    for i = 1 : numel(actions)
        % The following call will raise an exception if something wrong.
        % That's how we will know which test is not passing through.
        
        try
            nasa_toLustre.blocks.Stateflow.utils.getPseudoLusAction(actions{i}, false, true);
        catch
            display_msg(sprintf('Expression Failed: %s', actions{i}), ...
                MsgType.INFO, 'actionToLustreTest', '');
            notSupportedActions{end + 1} = actions{i};
        end
    end
    
    
    for i = 1 : numel(conditions)
        % The following call will raise an exception if something wrong.
        % That's how we will know which test is not passing through.
        try
            nasa_toLustre.blocks.Stateflow.utils.getPseudoLusAction(conditions{i}, true, true);
        catch
            display_msg(sprintf('Condition failed: %s', conditions{i}), ...
                MsgType.INFO, 'actionToLustreTest', '');
            notSupportedActions{end + 1} = conditions{i};
        end
    end
end

