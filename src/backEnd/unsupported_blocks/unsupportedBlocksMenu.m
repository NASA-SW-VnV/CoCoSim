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
function schema = unsupportedBlocksMenu(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Check Compatibility';
    schema.statustip = 'Check compatibility of your model with CoCoSim';
    schema.autoDisableWhen = 'Busy';
    
    schema.callback = @UnsupportedFunctionCallback;
end

function UnsupportedFunctionCallback(callbackInfo)
    global CoCoSimPreferences;
    CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    CoCoSimPreferences.skip_unsupportedblocks = false;
    model_full_path = MenuUtils.get_file_name(gcs);
    if ~strcmp(CoCoSimPreferences.lustreCompiler, 'NASA')
        msgbox(...
            sprintf('Check Compatibiity is only supported by the NASA Lustre compiler.\n Go to Tools -> Preferences -> Lustre Compiler -> NASA Compiler'), 'CoCoSim');
    else
        try
            MenuUtils.add_pp_warning(model_full_path);
            nasa_toLustre.ToLustreUnsupportedBlocks(model_full_path);
        catch me
            MenuUtils.handleExceptionMessage(me, 'Check Compatibility');
        end
    end
end



% Legacy code
% function schema = CheckModel(callbackInfo)
% schema = sl_action_schema;
% schema.label = 'Model';
% schema.callback = @(x) UnsupportedFunctionCallback(0,'', x);
% end
%
% function UnsupportedFunctionCallback(isSubsystem, SubsystemPath, callbackInfo)
% model_full_path = MenuUtils.get_file_name(gcs);
% if ~isSubsystem
%     try
%         nasa_toLustre.ToLustreUnsupportedBlocks(model_full_path);
%     catch me
%         display_msg(me.getReport(), MsgType.DEBUG, '', '');
%     end
% else
%     %     unsupportedOptions= nasa_toLustre.ToLustreUnsupportedBlocks(model_full_path, SubsystemName);
%     msgbox(sprintf('I am running %s', SubsystemPath));
% end
%
% end
%
%
% function schema = CheckSubsystem(SubsystemPath, isAction, callbackInfo)
% SubsysList = find_system(SubsystemPath, 'SearchDepth',1, 'BlockType', 'SubSystem');
% SubsysList = SubsysList(~strcmp(SubsysList, SubsystemPath));
% names = regexp(SubsystemPath,'/','split');
% subsystemName = names{end};
% if isAction
%     schema = sl_action_schema;
%     schema.label = subsystemName;
%     schema.callback = @(x) UnsupportedFunctionCallback(1,SubsystemPath, x);
% elseif isempty(SubsysList) && numel(names) == 1
%     schema = sl_action_schema;
%     schema.label = 'Selected Subsystem';
%     schema.state = 'Disabled';
%     schema.callback = @(x) UnsupportedFunctionCallback(1,SubsystemPath, x);
% elseif ~isempty(SubsysList)
%     schema = sl_container_schema;
%     if numel(names) == 1
%         schema.label = 'Selected Subsystem';
%     else
%         schema.label = regexprep(names{end}, '(\\n|\n)', ' ');
%     end
%     schema.statustip = 'Check compatibility for specific subsystem';
%     schema.autoDisableWhen = 'Busy';
%     callbacks = {};
%     for i=1:numel(SubsysList)
%         callbacks{end+1} =  @(x) CheckSubsystem(SubsysList{i},1, x);
%         if hsSubsystems(SubsysList{i})
%             callbacks{end+1} =  @(x) CheckSubsystem(SubsysList{i},0, x);
%         end
%     end
%     schema.childrenFcns = callbacks;
% end
%
% end
%
% function r = hsSubsystems(SubsystemPath)
% SubsysList = find_system(SubsystemPath, 'SearchDepth',1, 'BlockType', 'SubSystem');
% SubsysList = SubsysList(~strcmp(SubsysList, SubsystemPath));
% r = ~isempty(SubsysList);
% end