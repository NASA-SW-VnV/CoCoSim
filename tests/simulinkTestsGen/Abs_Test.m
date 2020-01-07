classdef Abs_Test < Block_Test
    %Abs_Test generates test automatically for Abs block
    
    properties(Constant)
        fileNamePrefix = 'Abs_TestGen';
        blkLibPath = 'simulink/Math Operations/Abs';
    end
    
    properties
        % properties that will participate in permutations
        inOutDataTypeKeys = {...
            'Inherit: auto', ...
            'single',...
            'double',...
            'int8', ...
            'uint8',...
            'int16',...
            'uint16'};
        inOutDataTypeValues = {...
            {'Inherit: Inherit via internal rule', 'Inherit: Inherit via back propagation', 'Inherit: Same as input', 'double','single','int8','uint8', 'int16','uint16'}, ... %'Inherit: auto'
            {'Inherit: Inherit via internal rule', 'Inherit: Same as input', 'single'},...        % 'single'
            {'Inherit: Inherit via internal rule', 'Inherit: Inherit via back propagation', 'double'},...        % 'double'
            {'Inherit: Inherit via internal rule', 'int8', 'uint8'},...        % 'int8'
            {'Inherit: Inherit via back propagation', 'int8', 'uint8'},...        % 'uint8'
            {'Inherit: Same as input', 'int16','uint16'},...        % 'int16'
            {'Inherit: Inherit via internal rule', 'int16','uint16'}        % 'uint16'
            };
        inOutDataTypeMap ; % defined in the constructor
        
        %         OutDataTypeStr = {...
        %             'Inherit: Inherit via internal rule', ...
        %             'Inherit: Inherit via back propagation', ...
        %             'Inherit: Same as input',...
        %             'double','single','int8','uint8','int8','uint8',...
        %             'int16','uint16','int16','uint16',...
        %             'int32','uint32','int32','uint32'};
        %
        %         inpDataType = {'Inherit: auto', ...
        %             'Inherit: auto', ...
        %             'Inherit: auto', ...
        %             'Inherit: auto', ...
        %             'single','double','int8', 'uint8','uint8','int8','uint8',...
        %             'int16','uint16','int16','uint16',...
        %             'int32','uint32','int32','uint32'};
    end
    
    properties
        % other properties
        
        %SampleTime = {'-1'};
        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', ...
            'Round', 'Simplest', 'Zero'};
        SaturateOnIntegerOverflow = {'off', 'on', 'on', 'off'};
        LockScale = {'off','on', 'off'};
        ZeroCross = {'off', 'on'};
        
    end
    
    
    methods
        % Constructor
        function obj = Abs_Test()
            obj.inOutDataTypeMap  = containers.Map(obj.inOutDataTypeKeys, obj.inOutDataTypeValues);
        end
    end
    
    
    methods
        % generateTests
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();
            fstInDims = {'1', '1', '2', '3', '[2,3]', '[3,4,2]'};
            nb_tests = length(params);
            condExecSSPeriod = floor(nb_tests/length(Block_Test.condExecSS));
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
                    
                    % remove parametres that does not belong to block params
                    inputDataType = s.inpDataType;
                    s = rmfield(s,'inpDataType');
                    % add the block
                    
                    Block_Test.add_and_connect_block(obj.blkLibPath, blkPath, s);
                    
                    %% go over inports
                    try
                        blk_parent = get_param(blkPath, 'Parent');
                    catch
                        blk_parent = fileparts(blkPath);
                    end
                    inport_list = find_system(blk_parent, ...
                        'SearchDepth',1, 'BlockType','Inport');
                    
                    set_param(inport_list{1}, ...
                        'OutDataTypeStr',inputDataType);
                    
                    dim_Idx = mod(i, length(fstInDims)) + 1;
                    set_param(inport_list{1}, ...
                        'PortDimensions', fstInDims{dim_Idx});
                    
                    failed = Block_Test.setConfigAndSave(mdl_name, mdl_path);
                    if failed
                        display(s);
                    end
                    
                    
                catch me
                    display(s);
                    display_msg(['Model failed: ' mdl_name], ...
                        MsgType.DEBUG, 'generateTests', '');
                    display_msg(me.getReport(), MsgType.ERROR, 'generateTests', '');
                    bdclose(mdl_name)
                end
            end
        end
        
        function new_params = getParams(obj)
            
            params = obj.getPermutations();
            new_params = cell(1, length(params));
            for i = 1 : length(params)
                s = params{i};
                
                iRound = mod(i, length(obj.RndMeth)) + 1;
                iSaturate = mod(i, length(obj.SaturateOnIntegerOverflow)) + 1;
                iLockScale = mod(i, length(obj.LockScale)) + 1;
                iZeroCross = mod(i, length(obj.ZeroCross)) + 1;
                
                s.RndMeth = obj.RndMeth{iRound};
                s.SaturateOnIntegerOverflow = obj.SaturateOnIntegerOverflow{iSaturate};
                s.LockScale = obj.LockScale{iLockScale};
                s.ZeroCross = obj.ZeroCross{iZeroCross};
                
                new_params{i} = s;
            end
        end
        
        function params = getPermutations(obj)
            params = {};
            inpDataType = obj.inOutDataTypeMap.keys();
            for inTypeIdx = 1:length(inpDataType)
                outDataTypeStr = obj.inOutDataTypeMap(inpDataType{inTypeIdx});
                for outTypeIdx = 1:length(outDataTypeStr)
                    s = struct();
                    s.inpDataType = inpDataType{inTypeIdx};
                    s.OutDataTypeStr = outDataTypeStr{outTypeIdx};
                    params{end+1} = s;
                end
            end
            
        end
        
    end
end

