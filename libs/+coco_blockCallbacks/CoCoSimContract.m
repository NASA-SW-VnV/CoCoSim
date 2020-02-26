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
classdef CoCoSimContract
    %COCOSIMCONTRACT provides callbacks of CoCosim Contract blocks
    
    properties(Constant)
        lib_name = 'cocosimLibs'
    end
    
    methods(Static)
        function modeCallback(block)
            % modeCallback
            % Modify Mode subsystem based on user input of number of
            % Requires/Ensures
            
            
            % handle Requires
            require_old_inports = find_system(block, 'FollowLinks', 'on', ...
                'LookUnderMasks', 'all',...
                'SearchDepth',1, 'Regexp', 'on', ...
                'BlockType', 'Inport', 'Name', 'require\d+');
            nb_requires = str2double(get_param(block, 'requirePorts'));
            require_Mux_path = strcat(block, '/Require_Mux');
            require_cst_path = strcat(block, '/Require_true');
            last_port_idx = 0;
            coco_blockCallbacks.CoCoSimContract.handleMux(...
                block, require_Mux_path, nb_requires, require_old_inports, ...
                require_cst_path, last_port_idx, 'require');
            
            % handle Ensures
            ensure_old_inports = find_system(block, 'FollowLinks', 'on', ...
                'LookUnderMasks', 'all',...
                'SearchDepth',1, 'Regexp', 'on', ...
                'BlockType', 'Inport', 'Name', 'ensure\d+');
            nb_ensures = str2double(get_param(block, 'ensurePorts'));
            ensure_Mux_path = strcat(block, '/Ensure_Mux');
            ensure_cst_path = strcat(block, '/Ensure_true');
            last_port_idx = nb_requires;
            coco_blockCallbacks.CoCoSimContract.handleMux(...
                block, ensure_Mux_path, nb_ensures, ensure_old_inports, ...
                ensure_cst_path, last_port_idx, 'ensure');
            
        end
        function  validatorCallback(block)
            %validatorCallback
            % Modify Validator subsystem based on user input of number of
            % Assumptions/Guarantees/Modes
            
            % handle Assumptions
            assume_old_inports = find_system(block, 'FollowLinks', 'on', ...
                'LookUnderMasks', 'all',...
                'SearchDepth',1, 'Regexp', 'on', ...
                'BlockType', 'Inport', 'Name', 'assume\d+');
            nb_Assumes = str2double(get_param(block, 'assumePorts'));
            assume_Mux_path = strcat(block, '/A_Mux');
            assume_cst_path = strcat(block, '/Assume_true');
            last_port_idx = 0;
            coco_blockCallbacks.CoCoSimContract.handleMux(...
                block, assume_Mux_path, nb_Assumes, assume_old_inports, ...
                assume_cst_path, last_port_idx, 'assume');
            
            % handle Guarantees
            guarantee_old_inports = find_system(block, 'FollowLinks', 'on', ...
                'LookUnderMasks', 'all',...
                'SearchDepth',1, 'Regexp', 'on', ...
                'BlockType', 'Inport', 'Name', 'guarantee\d+');
            nb_Guarantees = str2double(get_param(block, 'guaranteePorts'));
            guarantee_Mux_path = strcat(block, '/G_Mux');
            guarantee_cst_path = strcat(block, '/Guarantee_true');
            last_port_idx = nb_Assumes;
            coco_blockCallbacks.CoCoSimContract.handleMux(...
                block, guarantee_Mux_path, nb_Guarantees, guarantee_old_inports, ...
                guarantee_cst_path, last_port_idx, 'guarantee');
            
            % handle Modes
            mode_old_inports = find_system(block, 'FollowLinks', 'on', ...
                'LookUnderMasks', 'all',...
                'SearchDepth',1, 'Regexp', 'on', ...
                'BlockType', 'Inport', 'Name', 'mode\d+');
            nb_Modes = str2double(get_param(block, 'modePorts'));
            mode_Mux_path = strcat(block, '/M_Mux');
            mode_cst_path = strcat(block, '/Mode_true');
            last_port_idx = nb_Assumes + nb_Guarantees;
            coco_blockCallbacks.CoCoSimContract.handleMux(...
                block, mode_Mux_path, nb_Modes, mode_old_inports, ...
                mode_cst_path, last_port_idx, 'mode');
            
            % add new empty assume/guarantee/modes blocks if needed
            try
                if ~bdIsLoaded(coco_blockCallbacks.CoCoSimContract.lib_name)
                    load_system(which(coco_blockCallbacks.CoCoSimContract.lib_name));
                end
                dst_blkH = get_param(block, 'PortHandles');
                total_ports =   nb_Assumes + nb_Guarantees + nb_Modes;
                for i = 1 : total_ports
                    pos = get_param(dst_blkH.Inport(i), 'Position');
                    %150   154   340   201
                    x1 = pos(1) - 290; x2 = pos(1) - 90;
                    y1 = pos(2) - 50; y2 = y1 + 57;
                    line = get_param(dst_blkH.Inport(i), 'line');
                    if line > 0
                        % remove line if it's not connected to the right
                        % block
                        src = get_param(line, 'SrcBlockHandle');
                        msk_type = get_param(src, 'MaskType');
                    else
                        msk_type = '';
                    end
                    blockHandle = -1;
                    if i <= nb_Assumes ...
                            && ~strcmp(msk_type, 'ContractAssumeBlock')
                        
                        if line > 0, delete_line(line); end
                        blockHandle =  add_block(...
                            strcat(coco_blockCallbacks.CoCoSimContract.lib_name, '/Assume'),...
                            strcat(get_param(block, 'Parent'),'/','Assume'),...
                            'MakeNameUnique','on', ...
                            'Position',[x1, y1, x2, y2]);
                    elseif i > nb_Assumes && i <= nb_Assumes + nb_Guarantees ...
                            && ~strcmp(msk_type, 'ContractGuaranteeBlock')
                        
                        if line > 0, delete_line(line); end
                        blockHandle =  add_block(...
                            strcat(coco_blockCallbacks.CoCoSimContract.lib_name, '/Guarantee'),...
                            strcat(get_param(block, 'Parent'),'/','Guarantee'),...
                            'MakeNameUnique','on', ...
                            'Position',[x1, y1, x2, y2]);
                    elseif i > nb_Assumes + nb_Guarantees && i <= total_ports ...
                            && ~strcmp(msk_type, 'ContractModeBlock')
                        
                        if line > 0, delete_line(line); end
                        blockHandle =  add_block(...
                            strcat(coco_blockCallbacks.CoCoSimContract.lib_name, '/Mode'),...
                            strcat(get_param(block, 'Parent'),'/','Mode'),...
                            'MakeNameUnique','on', ...
                            'Position',[x1, y1, x2, y2]);
                    end
                    if blockHandle > 0
                        src_blkH = get_param(blockHandle,'PortHandles');
                        add_line(get_param(block, 'Parent'), src_blkH.Outport(1), dst_blkH.Inport(i),...
                            'autorouting', 'on');
                    end
                end
                
            catch %me
            end
        end
        
        function handleMux(block, mux_path, nb_ports, old_inports, true_cst_path, ...
                last_port_idx, inport_prefix)
            % this function is applied to Assumptions/Guarantees/Modes
            if nb_ports < 0 || isempty(nb_ports)
                nb_ports = 0;
            end
            if nb_ports == 0
                if isempty(old_inports) ...
                        && getSimulinkBlockHandle(true_cst_path) ~= -1
                    % no changes are needed for assumptions
                else
                    
                    coco_blockCallbacks.CoCoSimContract.removeBlocksLinkedToMe(mux_path);
                    pos = get_param(mux_path, 'Position');
                    x = pos(1); y = pos(2);
                    constant_handle = add_block('simulink/Commonly Used Blocks/Constant',...
                        true_cst_path,...
                        'Value','true',...
                        'OutDataTypeStr','boolean',...
                        'Position',[(x-50) y (x-20) (y+20)]);
                    set_param(mux_path, 'Inputs', '1');
                    src_blkH = get_param(constant_handle,'PortHandles');
                    dst_blkH = get_param(mux_path, 'PortHandles');
                    add_line(block, src_blkH.Outport(1), dst_blkH.Inport(1),...
                        'autorouting', 'on');
                end
                
            elseif length(old_inports) == nb_ports
                return;
                
            elseif length(old_inports) > nb_ports
                set_param(mux_path, 'Inputs', num2str(nb_ports));
                for i = length(old_inports):-1:nb_ports+1
                    try
                        portHandles = get_param(old_inports{i}, 'PortHandles');
                        line = get_param(portHandles.Outport(1), 'line');
                        delete_line(line);
                    catch
                    end
                    delete_block(old_inports{i});
                end
                return
            else
                set_param(mux_path, 'Inputs', num2str(nb_ports));
                assume_dst_blkH = get_param(mux_path, 'PortHandles');
                if isempty(old_inports)
                    coco_blockCallbacks.CoCoSimContract.removeBlocksLinkedToMe(mux_path);
                    pos = get_param(mux_path, 'Position');
                    x1 = pos(1) - 50; y1 = pos(2)-20; x2 = pos(3)-20;
                else
                    pos = get_param(old_inports{end}, 'Position');
                    x1 = pos(1); y1 = pos(2); x2 = pos(3);
                end
                
                for i = length(old_inports)+1 : nb_ports
                    y1 = (y1+20); y2 = y1+14;
                    port_idx = last_port_idx + i;
                    inport_handle = add_block('simulink/Ports & Subsystems/In1',...
                        strcat(block, '/',inport_prefix, num2str(i)),...
                        'OutDataTypeStr','boolean',...
                        'PortDimensions', '1', ...
                        'Port', num2str(port_idx), ...
                        'Position',[x1, y1, x2, y2]);
                    src_blkH = get_param(inport_handle,'PortHandles');
                    add_line(block, src_blkH.Outport(1), assume_dst_blkH.Inport(i),...
                        'autorouting', 'on');
                end
            end
        end
        
        function removeBlocksLinkedToMe(bHandle, removeMe)
            if nargin < 2
                removeMe = false;
            end
            portHandles = get_param(bHandle, 'PortHandles');
            for i=1:length(portHandles.Inport)
                line = get_param(portHandles.Inport(i), 'line');
                if line > 0
                    src = get_param(line, 'SrcBlockHandle');
                    delete_line(line);
                    coco_blockCallbacks.CoCoSimContract.removeBlocksLinkedToMe(src, true);
                end
            end
            if removeMe
                delete_block(bHandle);
            end
        end
    end
end

