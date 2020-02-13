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
%% construct EMF  model
function [status, new_name_path, emf_path, xml_trace] = construct_EMF_model(...
        lus_file_path, node_name, output_dir, organize_blocks)
    tools_config;
    new_name_path = '';
    xml_trace = [];
    status = coco_nasa_utils.MatlabUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end
    if ~exist('organize_blocks', 'var')
        organize_blocks = 0;
    end
    %1- Generate Simulink model from original Lustre file using EMF
    %backend.

    %generate emf json
    [emf_path, status] = ...
        coco_nasa_utils.LustrecUtils.generate_emf(lus_file_path, output_dir, ...
        LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end

    [~, lus_fname, ~] = fileparts(lus_file_path);
    %generate simulink model
    if ~strcmp(coco_nasa_utils.MatlabUtils.fileBase(lus_fname), node_name)
        new_model_name = coco_nasa_utils.SLXUtils.adapt_block_name(strcat(lus_fname,'_',node_name));
    else
        new_model_name = coco_nasa_utils.SLXUtils.adapt_block_name(strcat(lus_fname,'_EMF'));
    end
    clear lus2slx
    [status, new_name_path, xml_trace] = lus2slx(emf_path, output_dir, new_model_name, node_name, organize_blocks, 1);
    if status
        return;
    end

    %2- Create Simulink model containing both SLX1 and SLX2
    load_system(new_name_path);

    main_block_path = strcat(new_model_name,'/', coco_nasa_utils.SLXUtils.adapt_block_name(node_name));
    portHandles = get_param(main_block_path, 'PortHandles');
    nb_inports = numel(portHandles.Inport);
    nb_outports = numel(portHandles.Outport);
    m = max(nb_inports, nb_outports);
    set_param(main_block_path,'Position',[100 0 (100+250) (0+50*m)]);

    for i=1:nb_inports
        p = get_param(portHandles.Inport(i), 'Position');
        x = p(1) - 50;
        y = p(2);
        inport_name = strcat(new_model_name,'/In',num2str(i));
        add_block('simulink/Ports & Subsystems/In1',...
            inport_name,...
            'Position',[(x-10) (y-10) (x+10) (y+10)]);
        SrcBlkH = get_param(inport_name,'PortHandles');
        add_line(new_model_name, SrcBlkH.Outport(1), portHandles.Inport(i), 'autorouting', 'on');
    end

    for i=1:nb_outports
        p = get_param(portHandles.Outport(i), 'Position');
        x = p(1) + 50;
        y = p(2);
        outport_name = strcat(new_model_name,'/Out',num2str(i));
        add_block('simulink/Ports & Subsystems/Out1',...
            outport_name,...
            'Position',[(x-10) (y-10) (x+10) (y+10)]);
        DstBlkH = get_param(outport_name,'PortHandles');
        add_line(new_model_name, portHandles.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
    end
    %% Save system
    configSet = getActiveConfigSet(new_model_name);
    set_param(configSet, 'Solver', 'FixedStepDiscrete', 'FixedStep', '1');
    save_system(new_model_name,'','OverwriteIfChangedOnDisk',true);

end
