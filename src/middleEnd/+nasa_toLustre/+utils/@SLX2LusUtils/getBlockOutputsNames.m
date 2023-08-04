
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
%% get block outputs names: inlining dimension
function [names, names_dt] = getBlockOutputsNames(parent, blk, ...
        srcPort, xml_trace, main_sampleTime)
    % This function returns the names of the block
    % outputs.
    % Example : an Inport In with dimension [2, 3] will be
    % translated as : In_1, In_2, In_3, In_4, In_5, In_6.
    % where In_1 = In(1,1), In_2 = In(2,1), In_3 = In(1,2),
    % In_4 = In(2,2), In_5 = In(1,3), In_6 = In(2,3).
    % A block is defined by its outputs, if a block does not
    % have outports, like Outport block, than will be defined by its
    % inports. E.g, Outport Out with width 2 -> Out_1, out_2
    blksNamesDefinedByTheirInports = {'Outport', 'Goto'};
    needToLogTraceability = 0;
    if nargin > 3 && ~isempty(xml_trace)
        % this function is only called with "xml_trace" variable in
        % Block_To_Lustre classes.
        needToLogTraceability = 1;
    end
    names = {};
    names_dt = {};
    if isempty(blk) ...
            || (isempty(blk.CompiledPortWidths.Outport) ...
            && isempty(blk.CompiledPortWidths.Inport))
        return;
    end
    % case of block with 'auto' Type, we need to get the inports
    % datatypes.
    if numel(blk.CompiledPortDataTypes.Outport) == 1 ...
            && strcmp(blk.CompiledPortDataTypes.Outport{1}, 'auto') ...
            && ~isempty(blk.CompiledPortWidths.Inport)...
            && ~strcmp(blk.BlockType, 'SubSystem')
        
        if numel(blk.CompiledPortWidths.Inport) > 1 ...
                && strcmp(blk.BlockType, 'BusCreator')
            % e,g BusCreator DT is defined by all its inputs
            width = blk.CompiledPortWidths.Inport;
        else
            % e,g BusAssignment and other blocks DT are
            % defined by their first input
            width = blk.CompiledPortWidths.Inport(1);
        end
        portType = 'Inports';
        
    elseif isempty(blk.CompiledPortWidths.Outport) ...
            && ismember(blk.BlockType, blksNamesDefinedByTheirInports)
        width = blk.CompiledPortWidths.Inport;
        portType = 'Inports';
    else
        width = blk.CompiledPortWidths.Outport;
        portType = 'Outports';
    end
    
    function [names, names_dt] = blockOutputs(portNumber)
        %
        %
        names = {};
        names_dt = {};
        if strcmp(portType, 'Inports')
            slx_dt = blk.CompiledPortDataTypes.Inport{portNumber};
        else
            slx_dt = blk.CompiledPortDataTypes.Outport{portNumber};
        end
        if strcmp(slx_dt, 'auto')
            if strcmp(portType, 'Inports')
                % this is the case of virtual bus, we need to do back
                % propagation to find the real datatypes
                if isfield(blk, 'BusObject') && ~isempty(blk.BusObject)
                    isBus = coco_nasa_utils.SLXUtils.isSimulinkBus(blk.BusObject);
                    
                    if isBus
                        lus_dt =...
                            nasa_toLustre.utils.SLX2LusUtils.getLustreTypesFromBusObject(blk.BusObject);
                        isBus = false;
                    else
                        lus_dt = nasa_toLustre.utils.SLX2LusUtils.getpreBlockLusDT(parent, blk, portNumber);
                    end
                else
                    lus_dt = nasa_toLustre.utils.SLX2LusUtils.getpreBlockLusDT(parent, blk, portNumber);
                    isBus = false;
                end
            elseif strcmp(blk.BlockType, 'SubSystem')
                %get all blocks names
                fields = fieldnames(blk.Content);
                
                % remove blocks without BlockType (e.g annotations)
                fields = ...
                    fields(...
                    cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
                
                % get only blocks with BlockType=type
                Portsfields = ...
                    fields(...
                    cellfun(@(x) strcmp(blk.Content.(x).BlockType,'Outport'), fields));
                % get their ports number
                ports = cellfun(@(x) str2num(blk.Content.(x).Port), Portsfields);
                outportBlk = blk.Content.(Portsfields{ports == portNumber});
                lus_dt = nasa_toLustre.utils.SLX2LusUtils.getpreBlockLusDT( blk, outportBlk, 1);
                isBus = false;
            else
                try
                    pH = get_param(blk.Origin_path, 'PortHandles');
                    SignalHierarchy = get_param(pH.Outport(portNumber), ...
                        'SignalHierarchy');
                    [lus_dt] = nasa_toLustre.utils.SLX2LusUtils.SignalHierarchyLusDT(...
                        blk, SignalHierarchy);
                    isBus = false;
                catch me
                    display_msg(me.getReport(), MsgType.DEBUG, 'getBlockOutputsNames', '');
                    lus_dt = 'real';
                    isBus = false;
                end
                
            end
        else
            [lus_dt, ~, ~, isBus] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
        end
        % For PRELUDE
        if strcmp(parent.BlockType, 'block_diagram')...
                && strcmp(blk.BlockType, 'Inport') ...
                && isfield(blk,'CompiledSampleTime')...
                && isfield(parent,'CompiledSampleTime')
            blkT = blk.CompiledSampleTime(1);
            blkP = blk.CompiledSampleTime(2);
            parentT = parent.CompiledSampleTime(1);
            if blkP ~= 0
                p = sprintf('%d/%d', blkP/parentT, blkT/parentT);
            else
                p = '0';
            end
            rate = sprintf('rate(%.0f, %s)', ...
                blkT/parentT, p);
        else
            rate = '';
        end
        % The width should start from the port width regarding all
        % subsystem outputs
        idx = sum(width(1:portNumber-1))+1;
        for i=1:width(portNumber)
            if isBus
                for k=1:numel(lus_dt)
                    names{end+1} = nasa_toLustre.lustreAst.VarIdExpr(...
                        nasa_toLustre.utils.SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx), '_BusElem', num2str(k))));
                    names_dt{end+1} = nasa_toLustre.lustreAst.LustreVar(names{end} , lus_dt{k}, rate);
                end
            elseif iscell(lus_dt) && numel(lus_dt) == width(portNumber)                
                names{end+1} = nasa_toLustre.lustreAst.VarIdExpr(...
                    nasa_toLustre.utils.SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx))));
                names_dt{end+1} = nasa_toLustre.lustreAst.LustreVar(names{end}, char(lus_dt{i}), rate);
            else
                names{end+1} = nasa_toLustre.lustreAst.VarIdExpr(...
                    nasa_toLustre.utils.SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx))));
                names_dt{end+1} = nasa_toLustre.lustreAst.LustreVar(names{end}, char(lus_dt), rate);
            end
            idx = idx + 1;
        end
    end
    isInsideContract = nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
    IsNotInSimulink = false;
    if nargin >= 3 && ~isempty(srcPort) ...
            && ~strcmp(portType, 'Inports') % e.g.: BusCreator as source block case
        
        port = srcPort + 1;% srcPort starts by zero
        [names, names_dt] = blockOutputs(port);
        % traceability
        if needToLogTraceability
            for index=1:numel(names)
                xml_trace.add_Var(names{index}.getId(), ...
                    blk.Origin_path, port, numel(names), index, isInsideContract, IsNotInSimulink, portType);
            end
        end
    else
        for port=1:numel(width)
            [names_i, names_dt_i] = blockOutputs(port);
            names = [names, names_i];
            names_dt = [names_dt, names_dt_i];
            if needToLogTraceability
                for index=1:numel(names_i)
                    xml_trace.add_Var(names_i{index}.getId(), ...
                        blk.Origin_path, port, numel(names_i), index, isInsideContract, IsNotInSimulink, portType);
                end
            end
        end
    end
    
    %% set clocks
    if isfield(blk, 'CompiledSampleTime') && nargin >= 5
        [outTs, outTsOffset] = ...
            nasa_toLustre.utils.SLX2LusUtils.getSSSampleTime(blk.CompiledSampleTime, main_sampleTime);
        normalizedOutT = outTs / main_sampleTime(1);
        normalizedOutP = outTsOffset / main_sampleTime(1);
        if ~nasa_toLustre.utils.SLX2LusUtils.isIgnoredSampleTime(...
                normalizedOutT, normalizedOutP)
            clockInName =nasa_toLustre.utils.SLX2LusUtils.clockName(...
                normalizedOutT, normalizedOutP);
            for indx=1:length(names_dt)
                names_dt{indx}.clock = clockInName;
            end
        end
    end
end
