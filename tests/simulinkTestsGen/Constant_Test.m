classdef Constant_Test < Block_Test
    %Constant_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Constant_TestGen';
        blkLibPath = 'simulink/Sources/Constant';
    end
    
    properties
        % properties that will participate in permutations
        %OutDataTypeStr = {'double','single'};
        VectorParams1D = {'off','on'};
        Value = {'1','10','[1 2 4]', '[0 2; 3 4]'};
        OutDataTypeStr = {...
            'double','single','int8','uint8','int32',...
            'uint32'};        
    end
    
    properties
        % other properties
        SampleTime = {'-1'};
        OutMin = {'0','.5','5'};
        OutMax = {'0.1','.51','6','8'};        
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();                     
            nb_tests = length(params);
            condExecSSPeriod = floor(nb_tests/length(Block_Test.condExecSS));
            for i=1 : nb_tests
                skipTests = [];
                if ismember(i,skipTests)
                    continue;
                end
                try
                    s = params{i};
                    %% creat new model
                    mdl_name = sprintf('%s%d', obj.fileNamePrefix, i);
                    addCondExecSS = (mod(i, condExecSSPeriod) == 0);
                    condExecSSIdx = int32(i/condExecSSPeriod);
                    [blkPath, mdl_path, skip] = Block_Test.create_new_model(...
                        mdl_name, outputDir, deleteIfExists, addCondExecSS, ...
                        condExecSSIdx);
                    if skip
                        continue;
                    end
                    
                    %% remove parametres that does not belong to block params
%                     outDataType = s.outputDataType;
%                     s = rmfield(s,'outputDataType');
                    %% add the block

                    Block_Test.add_and_connect_block(obj.blkLibPath, blkPath, s);

                    failed = Block_Test.setConfigAndSave(mdl_name, mdl_path);
                    if failed, display(s), end
                
                    
                catch me
                    display(s);
                    display_msg(['Model failed: ' mdl_name], ...
                        MsgType.DEBUG, 'generateTests', '');
                    display_msg(me.getReport(), MsgType.ERROR, 'generateTests', '');
                    bdclose(mdl_name)
                end
            end
        end
        
        function params2 = getParams(obj)
            
            params1 = obj.getPermutations();
            params2 = cell(1, length(params1));
            for p1 = 1 : length(params1)
                s = params1{p1};                
                params2{p1} = s;
            end
        end
        
        function params = getPermutations(obj)
            params = {};
            for pValue = 1 : numel(obj.Value)
                for pOutDataTypeStr = 1:numel(obj.OutDataTypeStr)
                    for pVectorParams1D = 1:numel(obj.VectorParams1D)
                            s = struct();
                            s.Value = obj.Value{pValue};
                            s.VectorParams1D = obj.VectorParams1D{pVectorParams1D};
                            s.OutDataTypeStr = obj.OutDataTypeStr{pOutDataTypeStr};
                            params{end+1} = s;
                    end
                end
            end
            
        end

    end
end

