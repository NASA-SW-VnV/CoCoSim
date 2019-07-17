classdef MatlabFunction_Test < Block_Test
    %Bias_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'MatlabFunction_TestGen';
        blkLibPath = 'simulink/User-Defined Functions/MATLAB Function';
    end
    
    properties
        % properties that will participate in permutations
        inputDataType = {'double','single','int8',...
            'uint8','int32','uint32','fixdt(1,16,0)',...
            'boolean'};
        inputDimension = {'1', '1', '1', '1', '[3,1]', '[1,3]', '[2,3]'};
        oneInputFcn = { ...
            'y = all(u);',...
            'y = all(u, 1);',...
            'y = all(all(u));',...
            'y = all(u, 2);',...
            'y = any(u);',...
            'y = any(u, 1);',...
            'y = any(any(u));',...
            'y = any(u, 2);',...
            'y = length(u);',...
            'y = not(u);',...
            'y = numel(u);',...
            'y = sum(u);',...
            'y = sum(u, 1);',...
            'y = sum(sum(u));',...
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
                    oneInpFcn = s.oneInputFcn;
                    s = rmfield(s,'oneInputFcn');
                    %% add the block
                    Block_Test.add_and_connect_block(obj.blkLibPath, blkPath, s);
                    
                    % define MATLAB function
                    blockHandle = find(slroot, '-isa', ...
                        'Stateflow.EMChart', 'Path', blkPath);
                    header = 'function y = fcn(u)';
                    scripts = [header newline obj.oneInputFcn{oneInpFcn}];
                    %blockHandle.Script = fileread('fcn.m');
                    blockHandle.Script = scripts;
                    
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
            
            params1 = obj.getPermutations();
            params2 = cell(1, length(params1));
            for p1 = 1 : length(params1)
                s = params1{p1};                
                params2{p1} = s;
            end
        end
        
        function params = getPermutations(obj)
            params = {};
%             inpIsIntCount = 0;
            
            for pInType = 1 : numel(obj.inputDataType)
                for pInDim = 1:numel(obj.inputDimension)
                    for p1inputFunc = 1:numel(obj.oneInputFcn)
                        s = struct();
                        s.oneInputFcn = p1inputFunc;
                        s.inputDataType = obj.inputDataType{pInType};
                        s.inputDimension = obj.inputDimension{pInDim};
                        params{end+1} = s;
                    end
                end
            end
            
        end

    end
end

