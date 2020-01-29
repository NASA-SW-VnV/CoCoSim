classdef Merge_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Merge_To_Lustre support Merge block only in the case it is linked to
    % conditionally-executed subsystem.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            %% check if it is supported
            if strcmp(blk.AllowUnequalInputPortWidths, 'on')
                display_msg(sprintf('Merge block "%s" is not supported. CoCoSim supports only Merge blocks with equal Input Port widths', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'Merge_To_Lustre', '');
                return;
            end
            widths = blk.CompiledPortWidths.Inport;
            nb_input = numel(widths);
            is_supported = true;
            pre_blksConds = cell(1, nb_input);
            for i=1:nb_input
                pre_blk =nasa_toLustre.utils.SLX2LusUtils.getpreBlock(parent, blk, i);
                if isempty(pre_blk) 
                    is_supported = false;
                    break;
                elseif isempty(pre_blk.CompiledPortWidths.Enable)...
                        && isempty(pre_blk.CompiledPortWidths.Trigger)...
                        && isempty(pre_blk.CompiledPortWidths.Ifaction)
                    is_supported = false;
                    break;
                end
                pre_blksConds{i} = nasa_toLustre.lustreAst.VarIdExpr(...
                    nasa_toLustre.blocks.SubSystem_To_Lustre.getExecutionCondName(pre_blk));
            end
            if ~is_supported
                display_msg(sprintf('Merge block "%s" is not supported. CoCoSim supports only Merge blocks that are connected to conditionally-executed subsystem', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'Merge_To_Lustre', '');
                return;
            end
            %% Step 1: Get the block outputs names, 
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names
            
            % we initialize the inputs by empty cell.
            inputs = cell(1, nb_input);
            % save the information of the outport dataType, 
            outputDataType = blk.CompiledPortDataTypes.Outport{1};

            % Go over inputs, numel(widths) is the number of inputs. 
            
            for i=1:nb_input
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                
                
                % Get the input datatype
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                
                %converts the input data type(s) to the output datatype, if
                %needed. 
                if ~strcmp(inport_dt, outputDataType)
                    % this function return if a casting is needed
                    % "conv_format", a library or the name of casting node
                    % will be stored in "external_lib".
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(conv_format)
                        % always add the "external_lib" to the object
                        % external libraries, (so it can be declared in the
                        % overall lustre code).
                        obj.addExternal_libraries(external_lib);
                        % cast the input to the conversion format. In our
                        % example conv_format = 'int_to_real(%s)'. 
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            InitialOutput_cell =nasa_toLustre.utils.SLX2LusUtils.getInitialOutput(parent, blk,...
                blk.InitialOutput, outputDataType, numel(outputs));
            %% Step 4: start filling the definition of each output
            codes = cell(1, numel(outputs));
            % Go over outputs
            for i=1:numel(outputs)
                conds = cell(1, numel(pre_blksConds));
                thens = cell(1, numel(pre_blksConds) + 1);
                for j=1:numel(pre_blksConds)
                    conds{j} = pre_blksConds{j};
                    thens{j} = inputs{j}{i};
                end
                thens{j+1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW,...
                    InitialOutput_cell{i}, ...
                    nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE,  outputs{i}));
                codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i},...
                    nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
            end
            % join the lines and set the block code.
            obj.addCode( codes );
            
        end
        %%
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            
            if strcmp(blk.AllowUnequalInputPortWidths, 'on')
                obj.addUnsupported_options(sprintf('Merge block "%s" is not supported. CoCoSim supports only Merge blocks with equal Input Port widths', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            widths = blk.CompiledPortWidths.Inport;
            is_supported = true;
            for i=1:numel(widths)
                pre_blk =nasa_toLustre.utils.SLX2LusUtils.getpreBlock(parent, blk, i);
                if isempty(pre_blk) 
                    is_supported = false;
                    break;
                elseif isempty(pre_blk.CompiledPortWidths.Enable)...
                        && isempty(pre_blk.CompiledPortWidths.Trigger)...
                        && isempty(pre_blk.CompiledPortWidths.Ifaction)
                    is_supported = false;
                    break;
                end
            end
            if ~is_supported
                obj.addUnsupported_options(sprintf('Merge block "%s" is not supported. CoCoSim supports only Merge blocks that are connected to conditionally-executed subsystem', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
           options = obj.unsupported_options;
           
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

