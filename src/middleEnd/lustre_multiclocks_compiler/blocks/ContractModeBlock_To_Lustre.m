classdef ContractModeBlock_To_Lustre < Block_To_Lustre
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
        function  write_code(obj, parent, blk, varargin)
            
            if ~SLX2LusUtils.isContractBlk(parent)
                display_msg(sprintf('Mode block "%s" should not be outside a Contract Subsystem', blk.Origin_path),...
                    MsgType.ERROR, 'ContractModeBlock_To_Lustre', '');
                return;
            end
            widths = blk.CompiledPortWidths.Inport;
            nb_inputs = numel(widths);
            inputs = cell(1, nb_inputs);
                       
            for i=1:nb_inputs
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);

                % Get the input datatype
                inport_dt = blk.CompiledPortDataTypes.Inport(i);

                if ~strcmp(inport_dt, 'boolean')
                    % this function return if a casting is needed
                    % "conv_format", a library or the name of casting node
                    % will be stored in "external_lib".
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'boolean');
                    if ~isempty(external_lib)
                        % always add the "external_lib" to the object
                        % external libraries, (so it can be declared in the
                        % overall lustre code).
                        obj.addExternal_libraries(external_lib);
                        % cast the input to the conversion format. In our
                        % example conv_format = 'int_to_real(%s)'. 
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            blk_name = SLX2LusUtils.node_name_format(blk);
            code = ContractModeExpr(blk_name, inputs{1}, inputs{2});
            obj.setCode( code );
            
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            % add your unsuported options list here
            if ~SLX2LusUtils.isContractBlk(parent)
                obj.addUnsupported_options(...
                    sprintf('Mode block "%s" should not be outside a Contract Subsystem', blk.Origin_path));
            end
           options = obj.unsupported_options;
           
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

