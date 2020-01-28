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
function [new_model_path, new_model_name, status] = ...
        crete_model_from_subsystem(file_name, ss_path, output_dir )
    block_name_adapted = ...
        BUtils.adapt_block_name(MatlabUtils.naming(nasa_toLustre.utils.SLX2LusUtils.name_format(ss_path)));
    new_model_name = strcat(file_name,'_', block_name_adapted);
    new_model_name = BUtils.adapt_block_name(new_model_name);
    new_model_path = fullfile(output_dir, strcat(new_model_name,'.slx'));
    if exist(new_model_path,'file')
        if bdIsLoaded(new_model_name)
            close_system(new_model_name,0)
        end
        delete(new_model_path);
    end
    close_system(new_model_name,0);
    model_handle = new_system(new_model_name);
    CompiledPortDataTypes = SLXUtils.getCompiledParam(ss_path, 'CompiledPortDataTypes');
    blk_name = get_param(ss_path, 'Name');
    new_blkH = add_block(ss_path, ...
        strcat(new_model_name, '/', blk_name));
    newBlokPortHandles = get_param(new_blkH, 'PortHandles');
    %Inports
    status = 0;
    for i=1:numel(newBlokPortHandles.Enable)
        status = status + addInport(newBlokPortHandles.Enable(i),...
            CompiledPortDataTypes.Enable{i});
    end
    for i=1:numel(newBlokPortHandles.Ifaction)
        status = status + addInport(newBlokPortHandles.Ifaction(i), ...
            CompiledPortDataTypes.Ifaction{i});
    end
    for i=1:numel(newBlokPortHandles.Inport)
        status = status + addInport(newBlokPortHandles.Inport(i), ...
            CompiledPortDataTypes.Inport{i});
    end
    for i=1:numel(newBlokPortHandles.Reset)
        status = status + addInport(newBlokPortHandles.Reset(i), ...
            CompiledPortDataTypes.Reset{i});
    end
    for i=1:numel(newBlokPortHandles.Trigger)
        status = status + addInport(newBlokPortHandles.Trigger(i), ...
            CompiledPortDataTypes.Trigger{i});
    end
    %Outport
    for i=1:numel(newBlokPortHandles.Outport)
        status = status + addOutport(newBlokPortHandles.Outport(i));
    end
    try
        BlocksPosition_pp(new_model_path, 1);
    catch
    end
    %% Save system
    save_system(model_handle,new_model_path,'OverwriteIfChangedOnDisk',true);
    function status = addInport(newBlkPort, portDT)
        try
            status = 0;
            inport_name = fullfile(new_model_name, 'In1');
            inport_handle = add_block('simulink/Ports & Subsystems/In1',...
                inport_name,...
                'MakeNameUnique', 'on');
            if isValidDT(portDT)
                set_param(inport_handle, 'OutDataTypeStr', portDT);
            end
            inportPortHandles = get_param(inport_handle, 'PortHandles');
            add_line(new_model_name,...
                inportPortHandles.Outport(1), newBlkPort,...
                'autorouting', 'on');
        catch Me
            display_msg(Me.getReport(), ...
                MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
            status = 1;
        end
    end
    function status = addOutport(newBlkPort)
        try
            status = 0;
            outport_name = fullfile(new_model_name, 'Out1');
            outport_handle = add_block('simulink/Ports & Subsystems/Out1',...
                outport_name,...
                'MakeNameUnique', 'on');
            outportPortHandles = get_param(outport_handle, 'PortHandles');
            add_line(new_model_name,...
                newBlkPort, outportPortHandles.Inport(1),...
                'autorouting', 'on');
        catch Me
            display_msg(Me.getReport(), ...
                MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
            status = 1;
        end
    end
    function res = isValidDT(dt)
        res = ~isempty(regexp(dt, '^u?int\d+', 'match')) ...
            || strcmp(dt, 'double') || strcmp(dt, 'single')...
            || strcmp(dt, 'boolean');
    end
end

