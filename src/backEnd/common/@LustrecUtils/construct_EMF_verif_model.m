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
% 
function [status, new_name_path] = construct_EMF_verif_model(slx_file_name,...
        lus_file_path, node_name, output_dir)
    new_name_path = '';
    [status] = LustrecUtils.check_DType_and_Dimensions(slx_file_name);
    if status
        return;
    end
    tools_config;
    status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end
    %1- Generate Simulink model from original Lustre file using EMF
    %backend.

    %generate emf json
    [emf_path, status] = ...
        LustrecUtils.generate_emf(lus_file_path, output_dir, ...
        LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end
    %generate simulink model
    new_model_name = BUtils.adapt_block_name(strcat(slx_file_name,'_Verif'));
    clear lus2slx
    [status, new_name_path, ~] = lus2slx(emf_path, output_dir, new_model_name, node_name, 0, 1);
    if status
        return;
    end
    %2- Create Simulink model containing both SLX1 and SLX2
    load_system(new_name_path);

    emf_sub_path = fullfile(new_model_name, BUtils.adapt_block_name(node_name));
    emf_pos = get_param(emf_sub_path, 'Position');
    % copy contents of slx_file to a subsytem
    original_sub_path = fullfile(new_model_name, 'original');
    add_block('built-in/Subsystem', original_sub_path);
    load_system(slx_file_name);
    Simulink.BlockDiagram.copyContentsToSubSystem(slx_file_name, original_sub_path);
    %add inputs and outputs for original subsystem
    OrigSubPortHandles = get_param(original_sub_path, 'PortHandles');
    nb_inports = numel(OrigSubPortHandles.Inport);
    nb_outports = numel(OrigSubPortHandles.Outport);
    m = max(nb_inports, nb_outports);
    set_param(original_sub_path,'Position',[emf_pos(1), emf_pos(2), emf_pos(3), emf_pos(2) + 50 * m]);
    emf_pos(2) = emf_pos(2) + 50 * m + 50;
    set_param(emf_sub_path,'Position',[emf_pos(1), emf_pos(2), emf_pos(3), emf_pos(2) + 50 * m]);

    portHandlesEMF = get_param(emf_sub_path, 'PortHandles');
    emf_inport_idx = 1;
    for i=1:nb_inports
        p = get_param(OrigSubPortHandles.Inport(i), 'Position');
        x = p(1) - 50;
        y = p(2);
        inport_name = strcat(new_model_name,'/In',num2str(i));
        inport_handle = add_block('simulink/Ports & Subsystems/In1',...
            inport_name,...
            'MakeNameUnique', 'on', ...
            'Position',[(x-10) (y-10) (x+10) (y+10)]);
        inportPortHandle = get_param(inport_handle,'PortHandles');
        add_line(new_model_name,...
            inportPortHandle.Outport(1), OrigSubPortHandles.Inport(i),...
            'autorouting', 'on');
        %add the inport to emf subsytem, it depends to dimension we should
        %inline vectors
        code_on=sprintf('%s([], [], [], ''compile'')', new_model_name);
        eval(code_on);
        dim_struct = get_param(inport_handle, 'CompiledPortDimensions');
        code_off=sprintf('%s([], [], [], ''term'')', new_model_name);
        eval(code_off);
        isMatrix = false;
        if numel(dim_struct.Outport)==1
            dim = dim_struct.Outport;
        elseif numel(dim_struct.Outport)==2
            if (dim_struct.Outport(1)==1 || dim_struct.Outport(2)==1)
                dim = dim_struct.Outport(1) * dim_struct.Outport(2);
            else
                isMatrix = true;
                dim = dim_struct.Outport;
            end
        elseif numel(dim_struct.Outport) == 3
            if  (dim_struct.Outport(2)==1 || dim_struct.Outport(3)==1)
                dim = dim_struct.Outport(2) * dim_struct.Outport(3);
            else
                isMatrix = true;
                dim = dim_struct.Outport;
            end
        else
            msg = sprintf('Invalid inport "%s": We do not support dimension [%s].',...
                get_param(inport_handle, 'Name'), num2str(dim_struct.Outport));
            display_msg(msg, MsgType.ERROR, ...
                'compare_slx_lus','');
            status = 1;
            return;
        end
        if dim == 1
            add_line(new_model_name,...
                inportPortHandle.Outport(1), portHandlesEMF.Inport(emf_inport_idx), ...
                'autorouting', 'on');
            emf_inport_idx = emf_inport_idx + 1;
        elseif ~isMatrix
            emf_inport_idx = ...
                LustrecUtils.add_demux(new_model_name, emf_inport_idx, ...
                strcat('In',num2str(i)), dim, portHandlesEMF, inportPortHandle);
        elseif isMatrix
            for colon=1:dim(2)
                selector_path = strcat(new_model_name,'/Selector_',...
                    strcat('In',num2str(i)), num2str(colon));
                IndexParamArray{1} = num2str(colon);
                IndexParamArray{2} = '1';
                h = add_block('simulink/Signal Routing/Selector',...
                    selector_path,...
                    'MakeNameUnique', 'on', ...
                    'IndexMode', 'One-based',...
                    'IndexParamArray', IndexParamArray, ...
                    'NumberOfDimensions', '2',...
                    'IndexOptions','Index vector (dialog),Select all');
                concat_Porthandl = get_param(h, 'PortHandles');
                add_line(new_model_name,...
                    inportPortHandle.Outport(1),...
                    concat_Porthandl.Inport(1), ...
                    'autorouting', 'on');
                demuxID = strcat('In',num2str(i),'_', num2str(colon));
                emf_inport_idx = ...
                    LustrecUtils.add_demux(new_model_name, emf_inport_idx, ...
                    demuxID, dim(3), portHandlesEMF, concat_Porthandl);
            end
        end
    end
    % add verification subsystem
    emf_pos = get_param(emf_sub_path, 'Position');
    orig_pos = get_param(original_sub_path, 'Position');
    verif_pos(1) = emf_pos(3) + 100;
    verif_pos(2) = (emf_pos(2) + orig_pos(2)) / 2;
    verif_pos(3) = emf_pos(3) + 300;
    verif_pos(4) = (emf_pos(4) + orig_pos(4)) / 2;
    verif_sub_path = fullfile(new_model_name, 'verif');
    add_block('built-in/Subsystem', verif_sub_path, ...
        'Position',verif_pos, ...
        'TreatAsAtomicUnit', 'on');
    mask = Simulink.Mask.create(verif_sub_path);
    mask.Type = 'VerificationSubsystem';
    set_param(verif_sub_path, 'ForegroundColor', 'red');
    set_param(verif_sub_path, 'BackgroundColor', 'white');

    x = (50 * nb_outports +120) / 2;
    Assertion_path = strcat(verif_sub_path,'/assert');
    add_block('simulink/Model Verification/Assertion',...
        Assertion_path,...
        'MakeNameUnique', 'on',...
        'Position', [450, x - 20,  550,  x + 20]...
        );

    if nb_outports >= 2
        AND_path = strcat(verif_sub_path,'/AND');
        add_block('simulink/Logic and Bit Operations/Logical Operator',...
            AND_path,...
            'MakeNameUnique', 'on',...
            'NumInputPorts', num2str(nb_outports), ...
            'Position', [350, 75,  370,  50 * (nb_outports + 1)]...
            );
        add_line(verif_sub_path, ...
            strcat('AND', '/1'),...
            strcat('assert', '/1'),...
            'autorouting', 'on');
    end

    j = 1;
    for i=1:2:2*nb_outports
        inport_name1 = strcat(verif_sub_path,'/In',num2str(i));
        add_block('simulink/Ports & Subsystems/In1',...
            inport_name1,...
            'MakeNameUnique', 'on',...
            'Position', [50, 50*i,  70,  50*i + 20]...
            );
        inport_name2 = strcat(verif_sub_path,'/In',num2str(i+1));
        add_block('simulink/Ports & Subsystems/In1',...
            inport_name2,...
            'MakeNameUnique', 'on',...
            'Position', [50, 50*(i+1),  70,  50*(i+1) + 20]...
            );
        equal_path = strcat(verif_sub_path,'/Equal',num2str(j));
        add_block('simulink/Logic and Bit Operations/Relational Operator',...
            equal_path,...
            'MakeNameUnique', 'on',...
            'OutDataTypeStr', 'fixdt(1,16)', ...
            'Operator', '==', ...
            'Position', [150, 50*i+25,  170,  50*i + 45]...
            );

        add_line(verif_sub_path, ...
            strcat('In',num2str(i), '/1'), ...
            strcat('Equal',num2str(j), '/1'), ...
            'autorouting', 'on');
        add_line(verif_sub_path, ...
            strcat('In',num2str(i+1), '/1'),...
            strcat('Equal',num2str(j), '/2'),...
            'autorouting', 'on');

        % Add product of elements for vectors inports
        product_path = strcat(verif_sub_path,'/Product',num2str(j));
        add_block('simulink/Math Operations/Product of Elements',...
            product_path,...
            'MakeNameUnique', 'on',...
            'Position', [250, 50*i+25,  270,  50*i + 45]...
            );

        add_line(verif_sub_path, ...
            strcat('Equal',num2str(j), '/1'),...
            strcat('Product',num2str(j), '/1'),...
            'autorouting', 'on');

        if nb_outports >= 2
            add_line(verif_sub_path, ...
                strcat('Product',num2str(j), '/1'),...
                strcat('AND', '/',num2str(j)),...
                'autorouting', 'on');
        else
            add_line(verif_sub_path, ...
                strcat('Product',num2str(j), '/1'),...
                strcat('assert', '/1'),...
                'autorouting', 'on');
        end
        j = j + 1;
    end

    %link outports
    VerifportHandles = get_param(verif_sub_path, 'PortHandles');
    outport_idx = 0;

    for i=1:nb_outports
        add_line(new_model_name, OrigSubPortHandles.Outport(i), VerifportHandles.Inport(2*i-1), 'autorouting', 'on');
        code_on=sprintf('%s([], [], [], ''compile'')', new_model_name);
        eval(code_on);
        dim_struct = get_param(OrigSubPortHandles.Outport(i), 'CompiledPortDimensions');
        code_off=sprintf('%s([], [], [], ''term'')', new_model_name);
        eval(code_off);
        isMatrix = false;
        if numel(dim_struct)==1
            dim = dim_struct;
        elseif numel(dim_struct)==2
            if (dim_struct(1)==1 || dim_struct(2)==1)
                dim = dim_struct(1) * dim_struct(2);
            else
                isMatrix = true;
                dim = dim_struct;
            end
        elseif numel(dim_struct) == 3
            if  (dim_struct(2)==1 || dim_struct(3)==1)
                dim = dim_struct(2) * dim_struct(3);
            else
                isMatrix = true;
                dim = dim_struct;
            end
        else
            msg = sprintf('Invalid inport "%s": We do not support dimension [%s].',...
                get_param(OrigSubPortHandles.Outport(i), 'Name'), num2str(dim_struct));
            display_msg(msg, MsgType.ERROR, ...
                'compare_slx_lus','');
            status = 1;
            return;
        end

        if dim == 1
            outport_idx = outport_idx + 1;
            add_line(new_model_name, portHandlesEMF.Outport(outport_idx), VerifportHandles.Inport(2*i), 'autorouting', 'on');
        elseif ~isMatrix
            outport_idx = LustrecUtils.add_mux(new_model_name, outport_idx, 2*i, num2str(i), dim,...
                portHandlesEMF, VerifportHandles, 1, 1 );
        elseif isMatrix
            concat_path = strcat(new_model_name,'/Concatenate_',...
                strcat('Out',num2str(i)));
            NumInputs = dim(3);
            h = add_block('simulink/Math Operations/Vector Concatenate',...
                concat_path,...
                'MakeNameUnique', 'on', ...
                'NumInputs', num2str(NumInputs), ...
                'ConcatenateDimension', '2',...
                'Mode','Multidimensional array');
            concat_Porthandl = get_param(h, 'PortHandles');
            for colon=1:dim(3)

                muxID = strcat('Out',num2str(i),'_', num2str(colon));
                last_index = LustrecUtils.add_mux(new_model_name, outport_idx, colon, muxID, dim(2),...
                    portHandlesEMF, concat_Porthandl, dim(3), colon );
            end
            add_line(new_model_name,...
                concat_Porthandl.Outport(1),...
                VerifportHandles.Inport(2*i), ...
                'autorouting', 'on');
            outport_idx = last_index;
        end
    end    
    save_system(new_name_path);   %add inputs and outputs for EMF subsystem
end
