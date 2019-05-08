classdef Demux_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Demux_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            if strcmp(blk.BusSelectionMode, 'on')
                display_msg(sprintf('BusSelectionMode on is not supported in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Demux_To_Lustre', '');
            end
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);

            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            
            
            codes = cell(1, length(outputs));
            for i=1:length(outputs)
                codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{1}{i});
                %sprintf('%s = %s;\n\t', outputs{i}, inputs{1}{i});
            end
            
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            if strcmp(blk.BusSelectionMode, 'on')
                obj.addUnsupported_options(...
                    sprintf('BusSelectionMode on is not supported in block %s',...
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

