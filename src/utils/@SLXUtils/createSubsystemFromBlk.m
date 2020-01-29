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
%function status = createSubsystemFromBlk(blk_path)
    status = 0;
    try
        blk_name = get_param(blk_path, 'Name');
        try
            % localCreateSubSystem function only exists in newer
            % versions of Matlab
            h = get_param(blk_path, 'Handle');
            blkHandles = get_param(h, 'PortHandles');
            if numel(blkHandles.Outport) > 0
                l = get_param(blkHandles.Outport(1), 'line');
                dst_port_Handles = get_param(l, 'DstPortHandle');
                dstPortHandle = dst_port_Handles(1);
            else
                l = -1;
            end
            obj = get_param( bdroot(blk_path), 'Object');
            obj.localCreateSubSystem(h);

            %change name of Subsystem created to match the original
            %block name
            if l == -1
                return;
            end
            l = get_param(dstPortHandle, 'line');
            srcPortH = get_param(l, 'SrcPortHandle');
            subsystemPath = get_param(srcPortH, 'Parent');
            set_param(subsystemPath, 'Name', blk_name);
            return;
        catch
            %we will do it manually
        end
        % No need for this function in R2017b. But we do it for R2015b
        blokPortHandles = get_param(blk_path, 'PortHandles');
        parent = get_param(blk_path, 'Parent');
        ss_path = fullfile(parent, strcat(blk_name,'_tmp'));
        ss_handle = add_block('built-in/Subsystem',ss_path,...
            'MakeNameUnique', 'on');
        Simulink.ModelReference.DeleteContent.deleteContents(ss_handle);
        % make sure the name did not change
        ss_path = fullfile(parent, get_param(ss_handle, 'Name'));
        blk_new_path = fullfile(ss_path, blk_name);
        add_block(blk_path, blk_new_path);
        newBlokPortHandles = get_param(blk_new_path, 'PortHandles');
        %Inports
        for i=1:numel(newBlokPortHandles.Enable)
            status = status + addInport(newBlokPortHandles.Enable(i), blokPortHandles.Enable(i));
        end
        for i=1:numel(newBlokPortHandles.Ifaction)
            status = status + addInport(newBlokPortHandles.Ifaction(i), blokPortHandles.Ifaction(i));
        end
        for i=1:numel(newBlokPortHandles.Inport)
            status = status + addInport(newBlokPortHandles.Inport(i), blokPortHandles.Inport(i));
        end
        for i=1:numel(newBlokPortHandles.Reset)
            status = status + addInport(newBlokPortHandles.Reset(i), blokPortHandles.Reset(i));
        end
        for i=1:numel(newBlokPortHandles.Trigger)
            status = status + addInport(newBlokPortHandles.Trigger(i), blokPortHandles.Trigger(i));
        end
        %Outport
        for i=1:numel(newBlokPortHandles.Outport)
            status = status + addOutport(newBlokPortHandles.Outport(i), blokPortHandles.Outport(i));
        end

        if status
            return;
        end
        orient=get_param(blk_path,'orientation');
        pos=get_param(blk_path,'position');
        delete_block(blk_path);
        BlocksPosition_pp(ss_path, 0)
        set_param(ss_handle, 'orientation', orient);
        set_param(ss_handle, 'position', pos);
        set_param(ss_handle, 'Name', blk_name);
    catch me
        display_msg(me.getReport(), ...
            MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
        status = 1;
    end
    % nested functions
        function status = addInport(newBlkPort, origBlkPort)
            try
                status = 0;
                inport_name = fullfile(ss_path, 'In1');
                inport_handle = add_block('simulink/Ports & Subsystems/In1',...
                    inport_name,...
                    'MakeNameUnique', 'on');
                inportPortHandles = get_param(inport_handle, 'PortHandles');
                add_line(ss_path,...
                    inportPortHandles.Outport(1), newBlkPort,...
                    'autorouting', 'on');
                %this line is important to update ssBlockHandles
                ssBlockHandles = get_param(ss_path, 'PortHandles');
                line = get_param(origBlkPort, 'line');
                if line == -1
                    % no connected line
                    return;
                end
                srcPortHandle = get_param(line, 'SrcPortHandle');
                delete_line(line);
                add_line(parent,...
                    srcPortHandle, ssBlockHandles.Inport(end),...
                    'autorouting', 'on');
            catch Me
                display_msg(Me.getReport(), ...
                    MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
                status = 1;
            end
        end
        function status = addOutport(newBlkPort, origBlkPort)
            try
                status = 0;
                outport_name = fullfile(ss_path, 'Out1');
                outport_handle = add_block('simulink/Ports & Subsystems/Out1',...
                    outport_name,...
                    'MakeNameUnique', 'on');
                outportPortHandles = get_param(outport_handle, 'PortHandles');
                add_line(ss_path,...
                    newBlkPort, outportPortHandles.Inport(1),...
                    'autorouting', 'on');
                %this line is important to update ssBlockHandles
                ssBlockHandles = get_param(ss_path, 'PortHandles');
                line = get_param(origBlkPort, 'line');
                if line == -1
                    % no connected line
                    return;
                end
                dstPortHandles = get_param(line, 'DstPortHandle');
                delete_line(line);
                for d=dstPortHandles'
                    add_line(parent,...
                        ssBlockHandles.Outport(end), d,...
                        'autorouting', 'on');
                end
            catch Me
                display_msg(Me.getReport(), ...
                    MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
                status = 1;
            end
        end
end



