classdef Fcn_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Fcn_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        
        function  status = write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            
            inputs_dt{1} = arrayfun(@(x) 'real', (1:numel(inputs{1})), ...
                'UniformOutput', false);
            
            data_map = nasa_toLustre.blocks.Fcn_To_Lustre.createDataMap(inputs, inputs_dt);
            
            expected_dt = 'real';
            
            args.blkObj = obj;
            args.blk = blk;
            args.parent = parent;
            args.data_map = data_map;
            args.inputs = inputs;
            args.expected_lusDT = expected_dt;
            args.isSimulink = true;
            args.isStateFlow = false;
            args.isMatlabFun = false;
            [lusCode, status] = ...
                nasa_toLustre.utils.MExpToLusAST.translate(blk.Expr, args);
            
            if status
                display_msg(sprintf('Block %s is not supported', HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Fcn_To_Lustre.write_code', '');
                return;
            end
            
           
            obj.addCode(nasa_toLustre.lustreAst.LustreEq(outputs{1}, lusCode{1}));
            obj.addVariable(outputs_dt);
            
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            % calling write_code because this block manipulate Expressions.
            status = obj.write_code(parent, blk, [], varargin);
            if status
                obj.addUnsupported_options(sprintf('ParseError  character unsupported  %s in block %s', ...
                    blk.Expr, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        data_map = createDataMap(inputs, inputs_dt)
    end
end

