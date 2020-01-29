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
function [status, errors_msg] = NotConnectedPorts_pp( new_model_base )
    %NotConnectedPorts_pp connects not connected ports to Constant or
    %Terminator.
    
    status = 0;
    errors_msg = {};
    
    all_blocks = find_system(new_model_base,'LookUnderMasks', 'all');
    if not(isempty(all_blocks))
        
        for i=1:length(all_blocks)
            try
                
                try
                    parent = get_param(all_blocks{i},'Parent');
                    variant = get_param(parent, 'Variant');
                    if strcmp(variant, 'on')
                        continue;
                    end
                catch
                end
                try
                    obj = get_param(all_blocks{i},'Object');
                    portsConection = obj.PortConnectivity';
                catch
                    continue;
                end
                for p=portsConection
                    try
                        if numel(p.SrcBlock) == 1 ...
                                && p.SrcBlock == -1
                            
                            ground_path = fullfile(obj.Parent, 'UnconnectedPort');
                            pos = p.Position;
                            x = pos(1);
                            y = pos(2);
                            constant_handle = add_block('simulink/Sources/Ground',...
                                ground_path,...
                                'MakeNameUnique', 'on', ...
                                'Position',[(x-30) (y-10) (x-10) (y+10)]);
                            SrcBlkH = get_param(constant_handle, 'PortHandles');
                            DstBlkH = obj.PortHandles;
                            
                            if strcmp(p.Type, 'trigger')
                                portHandle = DstBlkH.Trigger(1);
                            elseif strcmp(p.Type, 'enable')
                                portHandle = DstBlkH.Enable(1);
                            elseif strcmp(p.Type, 'state')
                                portHandle = DstBlkH.State(1);
                            elseif strcmp(p.Type, 'ifaction')
                                portHandle = DstBlkH.Ifaction(1);
                            else
                                type = strrep(p.Type, 'LConn', '');
                                type = strrep(type, 'RConn', '');
                                port_numer = str2double(type);
                                portHandle = DstBlkH.Inport(port_numer);
                            end
                            
                            line = get_param(portHandle, 'line');
                            if line ~= -1
                                delete_line(line);
                            end
                            add_line(obj.Parent, SrcBlkH.Outport(1),...
                                portHandle, 'autorouting', 'on');
                            
                        elseif  isempty(p.SrcBlock) && isempty(p.DstBlock)
                            terminator_path = fullfile(obj.Parent, 'UnconnectedPort');
                            pos = p.Position;
                            x = pos(1);
                            y = pos(2);
                            term_handle = add_block('simulink/Sinks/Terminator',...
                                terminator_path,...
                                'MakeNameUnique', 'on', ...
                                'Position',[(x+10) (y-10) (x+20) (y+10)]);
                            DstBlkH = get_param(term_handle, 'PortHandles');
                            SrcBlkH = obj.PortHandles;
                            
                            port_numer = str2double(p.Type);
                            line = get_param(SrcBlkH.Outport(port_numer), 'line');
                            if line ~= -1
                                delete_line(line);
                            end
                            add_line(obj.Parent, SrcBlkH.Outport(port_numer),...
                                DstBlkH.Inport(1), 'autorouting', 'on');
                            
                        end
                    catch me
                        display_msg(me.getReport(), MsgType.DEBUG, 'NotConnectedPorts_pp', '');
                        continue;
                    end
                end
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('NotConnectedPorts pre-process has failed for block %s', all_blocks{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'NotConnectedPorts_pp', '');
    end
    
end