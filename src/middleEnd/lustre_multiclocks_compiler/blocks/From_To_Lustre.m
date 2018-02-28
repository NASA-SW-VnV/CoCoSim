classdef From_To_Lustre < Block_To_Lustre
    %Test_write a dummy class
    
    properties
    end
    
    methods
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            goToPath = find_system(parent.Origin_path,'SearchDepth',1,...
                'BlockType','Goto','GotoTag',blk.GotoTag);
            if ~isempty(goToPath)
                GotoHandle = get_param(goToPath{1}, 'Handle');
            else
                display_msg(sprintf('From block %s has no GoTo', blk.Origin_path),...
                    MsgType.WARNING, 'From_To_Lustre', '');
                return;
            end
            gotoBlk = get_struct(parent, GotoHandle);
            [goto_outputs, ~] = SLX2LusUtils.getBlockOutputsNames(gotoBlk);
            codes = {};
            for j=1:numel(outputs)
                codes{j} = sprintf('%s = %s;\n\t', outputs{j}, goto_outputs{j});
            end
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
            
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
    end
    
end

