classdef Product_Test < Block_Test
    %Product_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Product_TestGen';
        blkLibPath = 'simulink/Math Operations/Product';
    end
    
    properties
        % properties that will participate in permutations
        Inputs =  {'2','3','4'}; 
        Multiplication = {'Element-wise(.*)','Matrix(*)'};
        CollapseMode = {'All dimensions','Specified dimension'};
        CollapseDim =  {'1'};
        OutDataTypeStr = {'double','single','int8',...
            'uint8','int16','uint16','int32','uint32','int64',...
            'uint64','fixdt(1,16,0)','fixdt(1,16,2^0,0)'};
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32','fixdt(1,16,0)','fixdt(1,16,2^0,0)'};   
    end
    
    properties
        % other properties
        InputSameDT = {'off','on'};
        SampleTime = {'1'};
        OutMin = {'0.','1.'};
        OutMax = {'10','100'};        
        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', ...
            'Round', 'Simplest', 'Zero'};
        SaturateOnIntegerOverflow = {'off', 'on'};
        LockScale = {'off','on'};        
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();             
            fstInDims = {'1', '1', '1', '1', '1', '3','[2,3]'};          
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
                    for i=1:numel(inport_list)
                        if s.InputSameDT                        
                            set_param(inport_list{i}, ...
                                'OutDataTypeStr',s.OutDataTypeStr);     
                        else
                            set_param(inport_list{i}, ...
                                'OutDataTypeStr', inpDataType);
                        end
                        dim_Idx = mod(i, length(fstInDims)) + 1;
                        set_param(inport_list{i}, ...
                            'PortDimensions', fstInDims{dim_Idx});
                    end

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
            for pMultiplication = 1 : numel(obj.Multiplication)
                for pInputs = 1 : numel(obj.Inputs)
                    pOutDataTypeStr = ...
                        mod(length(params), ...
                        length(obj.OutDataTypeStr))...
                        + 1;
                    pInputSameDT = mod(length(params), ...
                        length(obj.InputSameDT))+ 1;
                    pinputDataType = mod(length(params), ...
                        length(obj.inputDataType))+ 1;
                    s = struct();
                    s.Inputs = obj.Inputs{pInputs};
                    s.Multiplication = obj.Multiplication{pMultiplication};
                    s.OutDataTypeStr = obj.OutDataTypeStr{pOutDataTypeStr};
                    s.InputSameDT = obj.InputSameDT{pInputSameDT};
                    s.inputDataType = obj.inputDataType{pinputDataType};
                    params{end+1} = s;
                end
            end
        end

    end
end

