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
function [actions, conditions] = getAllSFActions(regression_path)

    %GETALLSFACTIONS goes over a folder and get all state actions and
    %transitions actions.
    actions = {};
    conditions = {};
    mdl_models = dir(fullfile(regression_path,'**', '*.mdl'));
    slx_models = dir(fullfile(regression_path,'**', '*.slx'));
    all_models = [mdl_models; slx_models];
    models_name = {all_models.name};
    n = numel(models_name);
    if n==0
        display_msg('No Simulink model found', Constants.RESULT, 'getAllSFActions', '');
        return;
    end
    if isfield(all_models, 'folder')
        models_path = arrayfun(@(x) [x.folder '/' x.name], all_models, 'UniformOutput', 0);
    else
        models_path = models_name;
    end
    for i=1: numel(models_path)
        
        bdclose('all')
        slx_full_path = which(char(models_path{i}));
        load_system(slx_full_path);
        [~, base_name, ~] = fileparts(slx_full_path);
        if bdIsLibrary(base_name)
            continue;
        end
        display_msg(sprintf('running file %s number %d out of %d', base_name, i, n), ...
            MsgType.RESULT, 'getAllSFActions', '');
        rt = sfroot;
        m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name',base_name);
        charts = m.find('-isa','Stateflow.Chart');
        for j = 1 : numel(charts)
            allStates = charts(j).find('-isa', 'Stateflow.State');
            allTransitions = charts(j).find('-isa', 'Stateflow.Transition');
            for sId = 1:numel(allStates)
                display_msg(sprintf('State Expression:\n %s', allStates(sId).LabelString), ...
                    MsgType.INFO, 'getAllSFActions', '');
                stateAction = edu.uiowa.chart.state.StateParser.parse(allStates(sId).LabelString);
                Entry = cell(stateAction.entry);
                During = cell(stateAction.during);
                Exit = cell(stateAction.exit);
                display_msg(sprintf('Entry Expression: %s', coco_nasa_utils.MatlabUtils.strjoin(Entry, ';')), ...
                    MsgType.RESULT, 'getAllSFActions', '');
                display_msg(sprintf('During Expression: %s', coco_nasa_utils.MatlabUtils.strjoin(During, ';')), ...
                    MsgType.RESULT, 'getAllSFActions', '');
                display_msg(sprintf('Exit Expression: %s', coco_nasa_utils.MatlabUtils.strjoin(Exit, ';')), ...
                    MsgType.RESULT, 'getAllSFActions', '');
                actions = [actions, nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(Entry)];
                actions = [actions, nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(During)];
                actions = [actions, nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(Exit)];
            end
            for tId = 1 : numel(allTransitions)
                
                %transitionObject = edu.uiowa.chart.transition.TransitionParser.parse(allTransitions(tId).LabelString);
                [transitionObject, status, unsupportedExp] = nasa_toLustre.utils.TransitionLabelParser(allTransitions(tId).LabelString);
                Event = char(transitionObject.eventOrMessage);
                Condition = char(transitionObject.condition);
                ConditionAction = char(transitionObject.conditionAction);
                TransitionAction = char(transitionObject.transitionAction);
                if status
                    display_msg(sprintf('Transition Expression:\n %s', allTransitions(tId).LabelString), ...
                        MsgType.INFO, 'getAllSFActions', '');
                    display(transitionObject)
                    display(unsupportedExp)
                end
                actions = [actions, nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(ConditionAction)];
                actions = [actions, nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(TransitionAction)];
                conditions = [conditions, nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(Condition)];
                conditions = [conditions, nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(Event)];
            end
        end
    end
    actions = unique(actions);
    conditions = unique(conditions);
    mat_file = fullfile(regression_path, strcat('getAllSFActionsResult','.mat'));
    if exist(mat_file, 'file'), delete(mat_file);end
    save(mat_file, 'actions', 'conditions');
end

