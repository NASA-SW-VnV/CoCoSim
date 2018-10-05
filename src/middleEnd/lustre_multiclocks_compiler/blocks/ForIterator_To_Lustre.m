classdef ForIterator_To_Lustre < Block_To_Lustre
    %ForIterator_To_Lustre is partially supported by SubSystem_To_Lustre.
    %Here we add only not supported options
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            % join the lines and set the block code.
            obj.setCode( LustreEq(outputs{1}, SLX2LusUtils.iterationVariable()));
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            if isequal(blk.IterationSource, 'external')
                obj.addUnsupported_options(...
                    sprintf('Block "%s" has external iteration limit source. Only internal option is supported', ...
                    blk.Origin_path));
            end
            if isequal(blk.ExternalIncrement, 'on')
                obj.addUnsupported_options(...
                    sprintf('Block "%s" has external increment which is not supported.', ...
                    blk.Origin_path));
            end
            [~, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IterationLimit);
            if status
                obj.addUnsupported_options(...
                    sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.IterationLimit, blk.Origin_path));
            end
            %
            Actionblks = Block_To_Lustre.find_blocks(parent, 'BlockType', 'ActionPort');
            Enableblks = Block_To_Lustre.find_blocks(parent, 'BlockType', 'EnablePort');
            Actionblks = [Actionblks, Enableblks];
            if ~isempty(Actionblks)
                for i=1:numel(Actionblks)
                    if isfield(Actionblks{i}, 'InitializeStates') ...
                            && isequal(Actionblks{i}.InitializeStates, 'held')
                        obj.addUnsupported_options(...
                            sprintf('Bock "%s" has option "held" inside ForIterator Subsystem "%s". Only "reset" option is supported if the ActionPort block is inside a For Iterator Subsystem.',...
                            Actionblks{i}.Origin_path, parent.Origin_path));
                    elseif isfield(Actionblks{i}, 'StatesWhenEnabling') ...
                            && isequal(Actionblks{i}.StatesWhenEnabling, 'held')
                        obj.addUnsupported_options(...
                            sprintf('Bock "%s" has option "held" inside ForIterator Subsystem "%s". Only "reset" option is supported if the Enable Port block is inside a For Iterator Subsystem.',...
                            Actionblks{i}.Origin_path, parent.Origin_path));
                    else
                        try
                            action_parant = get_struct(parent, ...
                                regexprep(fileparts(Actionblks{i}.Origin_path), ...
                                fullfile(parent.Origin_path, '/'), ''));
                        catch me
                            continue;
                        end
                        ActionSS_Outports = Block_To_Lustre.find_blocks(action_parant, 'BlockType', 'Outport');
                        for j=1:numel(ActionSS_Outports)
                            if isfield(ActionSS_Outports{j}, 'OutputWhenDisabled') ...
                                    && isequal(ActionSS_Outports{j}.OutputWhenDisabled, 'held')
                                obj.addUnsupported_options(...
                                    sprintf('Bock "%s" has option "held" inside ForIterator Subsystem "%s". Only "reset" option is supported if the Outport block is inside a For Iterator Subsystem.',...
                                    ActionSS_Outports{j}.Origin_path, parent.Origin_path));
                            end
                        end
                    end
                end
            end
            %Blocks with memories
            all_blks = Block_To_Lustre.find_blocks(parent);
            for i=1:numel(all_blks)
                if isfield(all_blks{i}, 'StateName')
                    blk_parent = fileparts(all_blks{i}.Origin_path);
                    if ~isequal(parent.Origin_path, blk_parent)
                        obj.addUnsupported_options(...
                            sprintf('Bock "%s" is a memory block inside ForIterator Subsystem "%s". Memory blocks are only allowed in the first level of the For Iterator Subsystem.',...
                            all_blks{i}.Origin_path, parent.Origin_path));
                    end
                end
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    
end

