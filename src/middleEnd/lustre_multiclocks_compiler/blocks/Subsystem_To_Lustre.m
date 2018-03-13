classdef Subsystem_To_Lustre < Block_To_Lustre
    %Subsystem_To_Lustre translates a subsystem call to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            codes = {};
            if  isfield(blk, 'isEnabled') && blk.isEnabled == 1
                fields = fieldnames(subsys.Content);
                fields = ...
                    fields(...
                    cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));
                enablePortsFields = fields(...
                    cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'EnablePort'), fields));
                hasEnablePort = ~isempty(enablePortsFields);
                if hasEnablePort
                    blk_name = SLX2LusUtils.name_format(blk.Name);
                    EnableCondName = sprintf('Enable_%s', blk_name);
                    EnableCondVar = sprintf('%s:bool;', EnableCondName);
                    obj.addVariable(EnableCondVar);
                    enableportDataType = blk.CompiledPortDataTypes.Enable{1};
                    [lusEnableportDataType, zero] = SLX2LusUtils.get_lustre_dt(enableportDataType);
                    cond = {};
                    for i=1:blk.CompiledPortWidths.Enable
                        if strcmp(lusEnableportDataType, 'bool')
                            cond{i} = sprintf('%s', inputs{end}{i});
                        else
                            cond{i} = sprintf('%s > %s', inputs{end}{i}, zero);
                        end
                    end
                    EnableCond = MatlabUtils.strjoin(cond, ' or ');
                    if isfield(parent, 'isEnabled') && parent.isEnabled == 1
                        EnableCond = sprintf('%s and (%s)', ...
                            SLX2LusUtils.isEnabledStr(), EnableCond);
                    end
                    codes{numel(codes) + 1} = sprintf('%s = %s;\n\t'...
                        ,EnableCondName,  EnableCond);
                else
                    inputs = [inputs, {SLX2LusUtils.isEnabledStr()}];
                end
            end
            node_name = SLX2LusUtils.node_name_format(blk);
            x = MatlabUtils.strjoin(inputs, ',\n\t');
            y = MatlabUtils.strjoin(outputs, ',\n\t');
            codes{numel(codes) + 1} = ...
                sprintf('(%s) = %s(%s);\n\t', y, node_name, x);
            obj.setCode( MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    
end

