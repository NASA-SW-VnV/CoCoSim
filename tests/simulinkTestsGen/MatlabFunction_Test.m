classdef MatlabFunction_Test < Block_Test
    %Bias_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'MatlabFunction_TestGen';
        blkLibPath = 'simulink/User-Defined Functions/MATLAB Function';
    end
    
    properties
        % properties that will participate in permutations
        inputDataType = {'double','single','int8',...
            'uint8','int32','uint32', 'boolean', 'Bus: MyBus', 'Enum: Days'};
        inputDimension = {'1', '[3,1]', '[1,3]', '[2,3]', '[2 3 4]'};
        oneInputFcn = { ...
            'y = all(u);',...
            'y = all(u, 1);',...
            'y = all(u, 2);',...
            'y = any(u);',...
            'y = any(u, 1);',...
            'y = any(u, 2);',...
            'y = length(u);',...
            'y = not(u);',...
            'y = numel(u);',...
            'y = sum(u);',...
            'y = sum(u, 1);',...
            'y = sum(u, 2);',...
            'y = transpose(u);'};
        twoInputsFcn = { ...
            'y = or(u, v);',...
            'y = and(u, v);',...
            'y = xor(u, v);',...
            'y = plus(u, v);',...
            'y = minus(u, v);'};        
        matrixMultFcn = { ...
            'y = mtimes(u, v);',...
            'y = u * v;'};
        Expr = {'sum(u)'};
    end
    
    properties
        % other properties
        SaturateOnIntegerOverflow = {'off', 'on'};
  
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            %
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
                    inpDataType = s.inputDataType;
                    s = rmfield(s,'inputDataType');
                    inputDims  = s.inputDimension;
                    s = rmfield(s,'inputDimension');
                    inpFcnIndex = s.inpFcnIndex;
                    s = rmfield(s,'inpFcnIndex'); 
                    numInputs = s.numInputs;
                    s = rmfield(s,'numInputs'); 
                    % define MATLAB function
                    testFunctionScript = '';

                    if numInputs == 1                       
                        header = 'function y = fcn(u)';
                        testFunctionScript = ...
                            [header newline obj.oneInputFcn{inpFcnIndex}];
                    elseif numInputs == 2          
                        header = 'function y = fcn(u,v)';                      
                        testFunctionScript = ...
                            [header newline obj.inpFcnIndex{inpFcnIndex}]; 
                    else
                        header = 'function y = fcn(u)';
                        testFunctionScript = ...
                            [header newline obj.oneInputFcn{inpFcnIndex}];                        
                    end                    
                    

                    %% add the block
                    Block_Test.add_and_connect_block(obj.blkLibPath, blkPath, s);
                    

                    blockObj = find(slroot, '-isa', ...
                        'Stateflow.EMChart', 'Path', blkPath);
                    blockObj.Script = testFunctionScript;
                    
                    %% go over inports
                    try
                        blk_parent = get_param(blkPath, 'Parent');
                    catch
                        blk_parent = fileparts(blkPath);
                    end
                    inport_list = find_system(blk_parent, ...
                        'SearchDepth',1, 'BlockType','Inport');                 
                    
                    % rotate over input data type 
                    set_param(inport_list{1}, ...
                        'OutDataTypeStr',inpDataType);
                    
                    set_param(inport_list{1}, ...
                        'PortDimensions', inputDims);

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
            do_1_input = true;
            params2 = {}
            if do_1_input
                params1 = obj.get_1_input_Permutations();
                params2 = cell(1, length(params1));
                for p1 = 1 : length(params1)
                    s = params1{p1};
                    params2{p1} = s;
                end
            end
        end
        
        function params = get_1_input_Permutations(obj)
            params = {};
       
            for pInType = 1 : numel(obj.inputDataType)
                for pInDim = 1:numel(obj.inputDimension)
                    for pFunc = 1:numel(obj.oneInputFcn)
                        s = struct();
                        s.inpFcnIndex = pFunc;
                        s.numInputs = 1;
                        s.inputDataType = obj.inputDataType{pInType};
                        s.inputDimension = obj.inputDimension{pInDim};
                        params{end+1} = s;
                    end
                end
            end
            
        end
        function params = get_2_inputs_Permutations(obj)
            params = {};
           
            for pInType = 1 : numel(obj.inputDataType)
                for pInDim = 1:numel(obj.inputDimension)
                    for pFunc = 1:numel(obj.twoInputsFcn)
                        s = struct();
                        s.inpFcnIndex = pFunc;
                        s.numInputs = 2;
                        s.inputDataType = obj.inputDataType{pInType};
                        s.inputDimension = obj.inputDimension{pInDim};
                        params{end+1} = s;
                    end
                end
            end
            
        end        
    end
end

