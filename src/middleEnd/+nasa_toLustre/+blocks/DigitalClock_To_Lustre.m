classdef DigitalClock_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %DigitalClock translates the DigitalClock block to external node
    %discretizing simulation time.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            
            % normalize digitalsampleTime to number of steps
            digitalsampleTime = blk.CompiledSampleTime(1) / main_sampleTime(1);
            realTime =  VarIdExpr(SLX2LusUtils.timeStepStr());
            
            
            
            
            
            % out =  if (nb_steps mod digitalsampleTime) = 0
            %           then real_time else 0.0 -> pre out;
            
            cond2 = BinaryExpr(BinaryExpr.EQ,...
                BinaryExpr(BinaryExpr.MOD,...
                VarIdExpr(SLX2LusUtils.nbStepStr()),...
                IntExpr(digitalsampleTime)), ...
                IntExpr(0));
            else2 = IteExpr(...
                BinaryExpr(BinaryExpr.EQ,...
                VarIdExpr(SLX2LusUtils.nbStepStr()),...
                IntExpr(0)), ...
                RealExpr('0.0'), ...
                UnaryExpr(UnaryExpr.PRE, outputs{1}));
            codes = LustreEq(outputs{1}, ...
                IteExpr(cond2, ...
                realTime, ...
                else2));
            
            obj.setCode( codes);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            [~, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.SampleTime);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.SampleTime, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

