classdef From_To_Lustre < Block_To_Lustre
    %From_To_Lustre
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
            goToPath = find_system(parent.Origin_path,'SearchDepth',1,...
                'LookUnderMasks', 'all', 'BlockType','Goto','GotoTag',blk.GotoTag);
            if ~isempty(goToPath)
                GotoHandle = get_param(goToPath{1}, 'Handle');
            else
                display_msg(sprintf('From block %s has no GoTo', blk.Origin_path),...
                    MsgType.WARNING, 'From_To_Lustre', '');
                return;
            end
            gotoBlk = get_struct(parent, GotoHandle);
            [goto_outputs, ~] = SLX2LusUtils.getBlockOutputsNames(parent, gotoBlk);
            codes = {};
            for j=1:numel(outputs)
                codes{j} = sprintf('%s = %s;\n\t', outputs{j}, goto_outputs{j});
            end
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
            
            
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            goToPath = find_system(parent.Origin_path,'SearchDepth',1,...
                'LookUnderMasks', 'all', 'BlockType','Goto','GotoTag',blk.GotoTag);
            if isempty(goToPath)
                obj.addUnsupported_options...
                    (sprintf('From block %s has no GoTo', blk.Origin_path));
            end
            options = obj.unsupported_options;
            
        end
    end
    
end

