classdef DiscreteFirFilter_Test < Block_Test
    %DiscreteFirFilter_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'DiscreteFirFilter_TestGen';
        blkLibPath = 'simulink/Discrete/Discrete FIR Filter';
    end
    
    properties
        % properties that will participate in permutations
        CoefSource = {'Dialog parameters','Input port'};
        Coefficients = {'[0.5 0.5]'};    % vector
        InitialStates = {'0'};           %scalar or vector 
        OutDataTypeStr = {'Inherit: Same as input',...
            'Inherit: Same as accumulator','int8','uint8','int16',...
            'uint16','int32','uint32','int64','uint64'};
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32','boolean'};   
    end
    
    properties
        % other properties
        FilterStructure = {'Direct form'};
        InputProcessing = {'Columns as channels (frame based)',...
            'Elements as channels (sample based)'}
        SampleTime = {'1'};
        CoefMin = {'[]'};
        CoefMax = {'[]'};
        OutMin = {'0','.5','5'};
        OutMax = {'0.1','.51','6','8'};         
        TapSumDataTypeStr = {'Inherit: Same as input','int8','uint8',...
            'int16','uint16','int32','uint32'};
        CoefDataTypeStr = {'Inherit: Same word length as input',...
            'int8','uint8','int16','uint16','int32','uint32'};
        ProductDataTypeStr = {'Inherit: Inherit via internal rule',...
            'Inherit: Same as input','int8','uint8','int16','uint16',...
            'int32','uint32'};
        AccumDataTypeStr = {'Inherit: Inherit via internal rule',...
            'Inherit: Same as input','Inherit: Same as product output',...
            'int8','uint8','int16','uint16','int32','uint32'};
        StateDataTypeStr = {'Inherit: Same as input',...
            'Inherit: Same as accumulator','int8','uint8','int16',...
            'uint16','int32','uint32'};
        
        

        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', ...
            'Round', 'Simplest', 'Zero'};
        LockScale = {'off','on'};     
        SaturateOnIntegerOverflow = {'off','on'};
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();             
            fstInDims = {'1', '1', '1', '1', '1', '3'};          
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
%                     set_param(inport_list{1}, ...
%                         'OutDataTypeStr',inpDataType);
%                     
%                     dim_Idx = mod(i, length(fstInDims)) + 1;
%                     set_param(inport_list{1}, ...
%                         'PortDimensions', fstInDims{dim_Idx});

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
            for pCoefSource = 1 : numel(obj.CoefSource)
                for pOutDataTypeStr = 1 : numel(obj.OutDataTypeStr)
                    rotateInputType = mod(length(params), ...
                        length(obj.inputDataType)) + 1;
                    iRound = mod(length(params), ...
                        length(obj.RndMeth)) + 1;
                    rotate2 = mod(length(params), 2) + 1;
                    s = struct();
                    s.OutDataTypeStr = obj.OutDataTypeStr{pOutDataTypeStr};
                    s.CoefSource = obj.CoefSource{pCoefSource};
                    s.inputDataType = obj.inputDataType(rotateInputType);
                    s.RndMeth = obj.RndMeth{iRound};
                    s.LockScale = obj.LockScale{rotate2};
                    params{end+1} = s;
                end
            end
        end

    end
end

