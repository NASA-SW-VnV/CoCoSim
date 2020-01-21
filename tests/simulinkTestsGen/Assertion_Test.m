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
            'uint8','int16','uint16','boolean','Inherit: auto'};
        
    end
    
    properties
        % other properties
        Enabled = {'on'};
        %AssertionFailFcn = {''};
        StopWhenAssertionFail = {'off'};% 'on' will cause an error if the assertion is false
        %SampleTime = {'-1'};
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();
            fstInDims = {'1', '1', '2', '3', '[2,3]', '[3,4,2]'};
            nb_tests = length(params);
            
            condExecSSPeriod = floor(nb_tests/length(Block_Test.condExecSS));
            if condExecSSPeriod <= 1
                condExecSSPeriod = floor(nb_tests/3);
            end
            for i=1 : nb_tests
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
                    
                    dim_Idx = mod(i-1, length(fstInDims)) + 1;
                    set_param(inport_list{1}, ...
                        'PortDimensions', fstInDims{dim_Idx});
                    
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
        
        function params = getParams(obj)
            params = cell(1, length(obj.inputDataType));
            for pInType = 1 : length(obj.inputDataType)
                s = struct();
                s.Enabled = 'on';
                s.inputDataType = obj.inputDataType{pInType};
                s.AssertionFailFcn = '';
                s.StopWhenAssertionFail = 'off';
                params{pInType} = s;
            end
            
        end
        
    end
end

