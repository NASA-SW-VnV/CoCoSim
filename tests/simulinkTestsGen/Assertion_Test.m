classdef Assertion_Test < Block_Test
    %Assertion_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Assertion_TestGen';
        blkLibPath = 'simulink/Model Verification/Assertion';
    end
    
    properties
        % properties that will participate in permutations
        
        % inputDataType is not a block parameter
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32','boolean','Inherit: auto'};
      
    end
    
    properties
        % other properties
        Enabled = {'off','on'};
        AssertionFailFcn = {''};
        StopWhenAssertionFail = {'off', 'on'};
        SampleTime = {'-1'};
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();             
            fstInDims = {'1', '1', '1', '1', '1', '3', '[2,3]'};          
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
                    inpDataType = s.inputDataType;
                    s = rmfield(s,'inputDataType');
                    %% add the block

                    Block_Test.add_and_connect_block(obj.blkLibPath, blkPath, s);
                    
                    
                    
                    %% go over inports
                    try
                        blk_parent = get_param(blkPath, 'Parent');
                    catch
                        blk_parent = fileparts(blkPath);
                    end
                    inport_list = find_system(blk_parent, ...
                        'SearchDepth',1, 'BlockType','Inport');
                    
                    % rotate over input data type for U
                    set_param(inport_list{1}, ...
                        'OutDataTypeStr',inpDataType);
                    
                    dim_Idx = mod(i, length(fstInDims)) + 1;
                    set_param(inport_list{1}, ...
                        'PortDimensions', fstInDims{dim_Idx});

                    failed = Block_Test.setConfigAndSave(mdl_name, mdl_path);
                    if failed, display(s), end
                    
                    % Need outport, add sum block and outport 
                    add_block('simulink/Discontinuities/Saturation', ...
                        fullfile(blk_parent, 'Satur'), ...
                        'LowerLimit',lowerLimit,...
                        'UpperLimit',upperLimit);                   
                    
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
            for pEnabled = 1 : numel(obj.Enabled)
                for pInType = 1 : numel(obj.inputDataType)
                    s = struct();
                    s.Enabled = obj.Enabled{pEnabled};
                    s.inputDataType = obj.inputDataType{pInType};
                    rotate2 = mod(length(params), 2) + 1;
                    s.AssertionFailFcn = obj.AssertionFailFcn{1};
                    s.StopWhenAssertionFail = ...
                        obj.StopWhenAssertionFail{rotate2};
                    params{end+1} = s;
                end
            end
        end

    end
end

