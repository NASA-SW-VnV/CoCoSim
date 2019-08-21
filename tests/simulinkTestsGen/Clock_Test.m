classdef Clock_Test < Block_Test
    %Clock_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Clock_TestGen';
        blkLibPath = 'simulink/Sources/Clock';
    end
    
    properties
        % properties that will participate in permutations
        %OutDataTypeStr = {'double','single'};
        DisplayTime = {'off'};
        Decimation = {'1','10','100','1000'};
    end
    
    properties
        % other properties
  
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
            for pDisplayTime = 1 : numel(obj.DisplayTime)
                for pDecimation = 1:numel(obj.Decimation)
%                     pOutputDataType = mod(numel(params), ...
%                         length(obj.OutDataTypeStr)) + 1;
                    s = struct();
                    s.DisplayTime = obj.DisplayTime{pDisplayTime};
                    s.Decimation = obj.Decimation{pDecimation};
                    %s.OutDataTypeStr = obj.OutDataTypeStr{pOutputDataType};
                    params{end+1} = s;
                    
                end
            end
            
        end

    end
end

