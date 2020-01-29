classdef Signum_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Signum_To_Lustre
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
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            inputs = {};
            %             outputDataType = blk.CompiledPortDataTypes.Outport{1};
            %             [LusOutputDT,     ~] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            [lusInport_dt, zero, one] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(1));
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            
            
            
            codes = cell(1, numel(inputs{1}));
            if strcmp(lusInport_dt, 'bool')
                for j=1:numel(inputs{1})
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, ...
                        nasa_toLustre.lustreAst.IteExpr(inputs{1}{j}, nasa_toLustre.lustreAst.IntExpr(1), nasa_toLustre.lustreAst.IntExpr(0)));
                end
            else
                for j=1:numel(inputs{1})
                    code = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(...
                        {...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, inputs{1}{j}, zero), ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, inputs{1}{j}, zero)
                        }, ...
                        {...
                        one,...
                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, one), ...
                        zero
                        }) ;
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, code);
                end
            end
            
            obj.addCode( codes );
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

