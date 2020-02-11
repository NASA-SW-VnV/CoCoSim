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

function status = AddResettableSubsystemToIfBlock(model)
    %this function fix the issue of reseting blocks inside an If-Action block
    %if it is inside a Resettable Subsystem. It propagate resettable signal to
    %the If-Action Subsystems.
    %The model should be loaded.
    status = 0;
    %% get the list of Resettable subsystem
    resetBlockList = find_system(model, 'LookUnderMasks', 'all', ...
        'BlockType','ResetPort');
    resetBlockList = get_param(resetBlockList, 'Handle');
    % go over the list and apply the method.
    for i=1:numel(resetBlockList)
        ActionPortList = find_system(get_param(resetBlockList{i}, 'Parent'),...
            'LookUnderMasks', 'all', ...
            'BlockType','ActionPort');
        ActionPortList = get_param(ActionPortList, 'Handle');
        if ~isempty(ActionPortList)
            for j=1:numel(ActionPortList)
                %check if it has UnitDelay or Subsystem, if not no
                %need to process it
                ActionPortParent = get_param(ActionPortList{j}, 'Parent');
                Delays = find_system(ActionPortParent,...
                    'LookUnderMasks', 'all', ...,
                    'SearchDepth', 1,...
                    'BlockType','Delay');
                UnitDelays = find_system(ActionPortParent,...
                    'LookUnderMasks', 'all', ...
                    'SearchDepth', 1,...
                    'BlockType','UnitDelay');
                SSList = find_system(ActionPortParent,...
                    'LookUnderMasks', 'all', ...
                    'SearchDepth', 1,...
                    'BlockType','SubSystem');

                if isempty(UnitDelays) && isempty(Delays) && numel(SSList) ==1
                    continue;
                end
                display_msg(sprintf('Fixing block %s', get_param(ActionPortList{j}, 'Parent')), ...
                    MsgType.INFO, 'AddResettableSubsystemToIfBlock', '');
                try
                    status = Lus2SLXUtils.encapsulateWithReset(resetBlockList{i}, ActionPortList{j});
                    if status
                        display_msg('AddResettableSubsystemToIfBlock Failed', ...
                            MsgType.ERROR, 'AddResettableSubsystemToIfBlock', '');
                        break;
                    end
                catch me
                    display_msg(me.getReport(), ...
                        MsgType.ERROR, 'AddResettableSubsystemToIfBlock', '');
                    break;
                end
            end
        end
    end

end

