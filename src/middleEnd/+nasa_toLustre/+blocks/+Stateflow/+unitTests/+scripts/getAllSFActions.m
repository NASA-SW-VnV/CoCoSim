function [actions, conditions] = getAllSFActions(regression_path)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    %GETALLSFACTIONS goes over a folder and get all state actions and
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
                display_msg(sprintf('Entry Expression: %s', MatlabUtils.strjoin(Entry, ';')), ...
                    MsgType.RESULT, 'getAllSFActions', '');
                display_msg(sprintf('During Expression: %s', MatlabUtils.strjoin(During, ';')), ...
                    MsgType.RESULT, 'getAllSFActions', '');
                display_msg(sprintf('Exit Expression: %s', MatlabUtils.strjoin(Exit, ';')), ...
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

