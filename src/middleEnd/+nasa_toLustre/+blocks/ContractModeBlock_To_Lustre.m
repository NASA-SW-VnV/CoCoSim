classdef ContractModeBlock_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % ContractModeBlock_To_Lustre is translating Mode Subsystem by a mode
    % in cocospec:
    % mode mode_name(
    %   require first_input;
    %   ensure second_input;
    % );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        function obj = ContractModeBlock_To_Lustre()
            obj.ContentNeedToBeTranslated = 0;
        end
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            if ~nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent)
                display_msg(sprintf('Mode block "%s" should not be outside a Contract Subsystem', HtmlItem.addOpenCmd(blk.Origin_path)),...
                    MsgType.ERROR, 'ContractModeBlock_To_Lustre', '');
                return;
            end
            widths = blk.CompiledPortWidths.Inport;
            nb_inputs = numel(widths);
            inputs = cell(1, nb_inputs);
            
            for i=1:nb_inputs
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                
                % Get the input datatype
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                
                if ~strcmp(inport_dt, 'boolean')
                    % this function return if a casting is needed
                    % "conv_format", a library or the name of casting node
                    % will be stored in "external_lib".
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'boolean');
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
            requires = cell(1, length(inputs{1}));
            for i=1:length(inputs{1})
                requires{i} = nasa_toLustre.lustreAst.ContractRequireExpr(inputs{1}{i});
            end
            ensure_blk = nasa_toLustre.utils.SLX2LusUtils.getpreBlock(parent, blk, 2);
            prop_ID =nasa_toLustre.utils.SLX2LusUtils.node_name_format(ensure_blk);
            
            ensures = cell(1, length(inputs{2}));
            for i=1:length(inputs{2})
                ensures{i} = nasa_toLustre.lustreAst.ContractEnsureExpr(prop_ID, inputs{2}{i});
                %prop_ID_i = sprintf('%s_%d', prop_ID, i);
                xml_trace.add_Property(...
                    ensure_blk.Origin_path, ...
                    nasa_toLustre.utils.SLX2LusUtils.node_name_format(parent),...
                    prop_ID, i, 'ensure');
            end
            
            blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            code = nasa_toLustre.lustreAst.ContractModeExpr(blk_name, requires, ensures);
            obj.addCode( code );
            
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            % add your unsuported options list here
            if ~nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent)
                obj.addUnsupported_options(...
                    sprintf('Mode block "%s" should not be outside a Contract Subsystem', HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

