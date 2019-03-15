classdef Sigbuilderblock_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        function  write_code(obj, parent, blk, xml_trace, lus_backend, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [time,data,~] = signalbuilder(blk.Origin_path);
            blkParams = nasa_toLustre.blocks.Sigbuilderblock_To_Lustre.readBlkParams(blk);
            
            model_name = strsplit(blk.Origin_path, '/');
            model_name = model_name{1};
            SampleTime = SLXUtils.getModelCompiledSampleTime(model_name);            
            
            %blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
%             if numel(outputs) > 1
%                 codes = cell(1, numel(outputs));
%                 for i=1:numel(outputs)
%                     codeAst = getSigBuilderCode(obj, time{i}, data{i},i,blk_name);
%                     codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, codeAst);
%                 end
%                 obj.addCode( codes );
%             elseif  numel(outputs) == 1
%                 codeAst = getSigBuilderCode(obj, time, data,1,blk_name);
%                 obj.addCode(codeAst);
%             end
            [codeAst, vars, external_lib] = getSigBuilderCode(obj, outputs,...
                time, data,SampleTime,blkParams,lus_backend);
            if ~isempty(external_lib)
                obj.addExternal_libraries(external_lib);
            end            
            obj.addVariable(vars);
            obj.addCode(codeAst);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        %%
        [codeAst_all, vars_all, external_lib] = getSigBuilderCode(...
                obj,outputs,time,data,SampleTime,blkParams,lus_backend)

    end
    methods (Static)
        
        blkParams = readBlkParams(blk)

        [codeAst, vars] = interpTimeSeries(output,time_array, ...
                data_array, blkParams,signal_index,interpolate,curTime,lus_backend)

    end
end

