classdef MatlabFunction_Test < Block_Test
    %Bias_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'MatlabFunction_TestGen';
        blkLibPath = 'simulink/User-Defined Functions/MATLAB Function';
    end
    
    properties
        supportedFun = {'all', 'any', 'circshift', 'sum', 'transpose'};
        %supportedFun = {'any'};
    end
    
    
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            for f=1:length(obj.supportedFun)
                fun_name = sprintf('matlabFunction_%sTest', obj.supportedFun{f});
                fun_handle = str2func(fun_name);
                params = fun_handle();
                nb_tests = length(params);
                for i=1 : nb_tests
                    skipTests = [];
                    if ismember(i,skipTests)
                        continue;
                    end
                    try
                        param = params{i};
                        %% creat new model
                        mdl_name = sprintf('%s_%s%d', obj.fileNamePrefix, ...
                            obj.supportedFun{f}, i);
                        addCondExecSS = false;
                        new_output_dir = fullfile(outputDir, obj.supportedFun{f});
                        MatlabUtils.mkdir(new_output_dir);
                        [blkPath, mdl_path, skip] = Block_Test.create_new_model(...
                            mdl_name, new_output_dir, deleteIfExists, addCondExecSS);
                        if skip
                            continue;
                        end
                        
                        %% add the block
                        add_block(obj.blkLibPath, blkPath);
                        blockObj = find(slroot, '-isa', ...
                            'Stateflow.EMChart', 'Path', blkPath);
                        blockObj.Script = param.Script;
                        Block_Test.connectBlockToInportsOutports(blkPath);
                        
                        %% go over inports
                        try
                            blk_parent = get_param(blkPath, 'Parent');
                        catch
                            blk_parent = fileparts(blkPath);
                        end
                        inport_list = find_system(blk_parent, ...
                            'SearchDepth',1, 'BlockType','Inport');
                        
                        % rotate over input data type
                        for in=1:length(inport_list)
                            set_param(inport_list{in}, ...
                                'OutDataTypeStr',param.inDT{in});
                            
                            set_param(inport_list{in}, ...
                                'PortDimensions', param.inDim{in});
                        end
                        failed = Block_Test.setConfigAndSave(mdl_name, mdl_path);
                        if failed, display(param), end
                        
                        
                    catch me
                        display(param);
                        display_msg(['Model failed: ' mdl_name], ...
                            MsgType.DEBUG, 'generateTests', '');
                        display_msg(me.getReport(), MsgType.ERROR, 'generateTests', '');
                        bdclose(mdl_name)
                    end
                end
            end
        end
        
        
    end
end

