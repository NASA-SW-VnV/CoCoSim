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

function status = encapsulateWithReset(resetBlock, actionBlock)
    status = 0;
    resetBlockParent = get_param(resetBlock, 'Parent');
    actionPortParent = get_param(actionBlock, 'Parent');
    %% First step: create resetable subsystem in the action block
    blocks = find_system(actionPortParent, ...
        'SearchDepth', 1, 'Regexp', 'on', 'BlockType','[^ActionPort]');
    bh = [];
    for i = 2:length(blocks)
        bh = [bh get_param(blocks{i}, 'handle')];
    end
    Simulink.BlockDiagram.createSubsystem(bh);
    resetSubsysName = find_system(actionPortParent,'SearchDepth', 1, 'BlockType', 'SubSystem' );
    resetSubsysName = resetSubsysName{2};
    % add Reset Port
    resetPortPath = fullfile(resetSubsysName, 'Reset');
    add_block('simulink/Ports & Subsystems/Resettable Subsystem/Reset', resetPortPath);
    try
        % in 2017 version of Simulink there is level hold
        % option, but not on the other Simulink versions
        set_param(resetPortPath, 'ResetTriggerType', 'level hold');
        isEither = false;
    catch
        set_param(resetPortPath, 'ResetTriggerType', 'either');
        isEither = true;
    end
    inport_path = BUtils.get_unique_block_name(...
        strcat(actionPortParent,'/','_Reset_Inport'));
    subsystemPosition = get_param(resetSubsysName, 'Position');
    x = subsystemPosition(1) - 60;
    y = subsystemPosition(2) - 60;
    inportHandle = add_block('simulink/Ports & Subsystems/In1',...
        inport_path,...
        'MakeNameUnique', 'on', ...
        'Position',[x y (x+20) (y+20)]);

    if isEither
        if ~bdIsLoaded('pp_lib'); load_system('pp_lib.slx'); end
        eitherTrigger_path =  BUtils.get_unique_block_name(...
            strcat(actionPortParent,'/','_reset_Either'));
        add_block('pp_lib/bool_To_eitherTrigger',...
            eitherTrigger_path);
        SrcBlkH = get_param(inportHandle, 'PortHandles');
        DstBlkH = get_param(eitherTrigger_path,'PortHandles');
        add_line(actionPortParent, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
        SrcBlkH = get_param(eitherTrigger_path, 'PortHandles');
        DstBlkH = get_param(resetSubsysName,'PortHandles');
        add_line(actionPortParent, SrcBlkH.Outport(1), DstBlkH.Reset(1), 'autorouting', 'on');
    else
        SrcBlkH = get_param(inportHandle, 'PortHandles');
        DstBlkH = get_param(resetSubsysName,'PortHandles');
        add_line(actionPortParent, SrcBlkH.Outport(1), DstBlkH.Reset(1), 'autorouting', 'on');
    end
    %% Second step, add Reset inport from "actionBlock" to "resetSubsys".
    if ~bdIsLoaded('pp_lib'); load_system('pp_lib.slx'); end
    while(~strcmp(resetBlockParent, actionPortParent))
        % add inport to actionPortParent
        parent = get_param(actionPortParent, 'Parent');
        inport_path = BUtils.get_unique_block_name(...
            strcat(parent,'/','_Reset_Inport'));

        ActionPortList = find_system(actionPortParent,...
            'SearchDepth', 1, ...
            'LookUnderMasks', 'all', ...
            'BlockType','ActionPort');
        subsystemPosition = get_param(actionPortParent, 'Position');
        x = subsystemPosition(3) - 60;
        y = subsystemPosition(4) - 60;
        actionSSHandles = get_param(actionPortParent,'PortHandles');
        if isempty(ActionPortList)

            inportHandle = add_block('simulink/Ports & Subsystems/In1',...
                inport_path,...
                'MakeNameUnique', 'on', ...
                'Position',[x y (x+20) (y+20)]);
            SrcBlkH = get_param(inportHandle, 'PortHandles');
            add_line(parent, SrcBlkH.Outport(1), actionSSHandles.Inport(end), 'autorouting', 'on');
        else
            % this case is more complicated, the actionPortParent
            % is an Action Subsystem and might be inactive on the
            % time of reset, we need to keep track about that
            % information.
            % add shouldBeReseted SS
            shouldBeReseted_path =  BUtils.get_unique_block_name(...
                strcat(parent,'/','_shouldBeReseted'));
            add_block('pp_lib/shouldBeReseted',...
                shouldBeReseted_path, ...
                'Position',[x y (x+50) (y+50)]);
            shouldBeResetedHandles = get_param(shouldBeReseted_path, 'PortHandles');
            % add inport
            subsystemPosition = get_param(shouldBeReseted_path, 'Position');
            x = subsystemPosition(3) - 60;
            y = subsystemPosition(4) + 60;
            inportHandle = add_block('simulink/Ports & Subsystems/In1',...
                inport_path,...
                'MakeNameUnique', 'on', ...
                'Position',[x y (x+20) (y+20)]);

            % add is Active condition that is related to the
            % actionPortSubsystem
            line = get_param(actionSSHandles.Ifaction, 'line');
            p = get_param(line, 'SrcPortHandle');
            portNumber = get_param(p, 'PortNumber');
            IfBlock = get_param(line, 'SrcBlockHandle');
            IfExp = get_param(IfBlock, 'IfExpression');
            isElse = 0;
            if iscell(IfExp) && portNumber <= numel(IfExp)
                condition = IfExp{portNumber};
            elseif iscell(IfExp) 
                %portNumber > numel(IfExp)
                isElse = 1;
            elseif portNumber == 1
                condition = IfExp;
            else
                isElse = 1;
            end

            if isElse
                elseExp = get_param(IfBlock, 'ElseIfExpressions');
                expIdx = portNumber - 1; % remove If condition
                if iscell(elseExp)
                    condition = elseExp{expIdx};
                elseif MatlabUtils.contains(elseExp, ',')
                    elseExp = split(elseExp, ',');
                    condition = elseExp{expIdx};
                else
                    condition = elseExp;
                end
            end
            if strcmp(condition, 'u1')
                operator = '~=';
                constant = '0';
            elseif strcmp(condition, '~u1')
                operator = '==';
                constant = '0';
            else
                operator = '==';
                constant = strrep(condition, 'u1 == ', '');
            end
            compareToConstantPath =  BUtils.get_unique_block_name(...
                strcat(parent,'/','_Is_Active'));
            x = subsystemPosition(1) - 60;
            y = subsystemPosition(2) - 60;
            add_block('simulink/Logic and Bit Operations/Compare To Constant',...
                compareToConstantPath,...
                'relop', operator,...
                'const', constant,...
                'Position',[x y (x+50) (y+50)]);

            % link If inport to compareToConstant
            IfBlockHandles = get_param(IfBlock,'PortHandles');
            line = get_param(IfBlockHandles.Inport(1), 'line');
            srcPortHandle = get_param(line, 'SrcPortHandle');
            compareToConstantHandles = get_param(compareToConstantPath,'PortHandles');
            add_line(parent, srcPortHandle, compareToConstantHandles.Inport(1), 'autorouting', 'on');

            % link compareToConstant to shouldBeReseted
            add_line(parent, compareToConstantHandles.Outport(1), shouldBeResetedHandles.Inport(1), 'autorouting', 'on');
            % link shouldBeReseted to actionPort SS
            add_line(parent, shouldBeResetedHandles.Outport(1), actionSSHandles.Inport(end), 'autorouting', 'on');

            %link reset inport to shouldBeReseted SS.
            SrcBlkH = get_param(inportHandle, 'PortHandles');
            add_line(parent, SrcBlkH.Outport(1), shouldBeResetedHandles.Inport(2), 'autorouting', 'on');
        end
        actionPortParent = parent;
    end

    %% Third step: link the Reset signal
    SrcBlkH = get_param(resetBlockParent, 'PortHandles');
    l = get_param(SrcBlkH.Reset(1), 'line');
    if l == -1
        status = 1;
        return;
    end
    srcPortHandle = get_param(l, 'SrcPortHandle');
    add_line(get_param(resetBlockParent, 'Parent'), srcPortHandle, SrcBlkH.Inport(end), 'autorouting', 'on');
end

