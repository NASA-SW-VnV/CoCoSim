classdef Delay_Test < Block_Test
    %Delay_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Delay_TestGen';
        blkLibPath = 'simulink/Discrete/Delay';
    end
    
    properties
        % properties that will participate in permutations
        DelayLengthSource = {'Dialog','Input port'};
        DelayLength = {'2','4'};
        InitialConditionSource = {'Dialog','Input port'};
 
    end
    
    properties
        % other properties
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32','boolean'};  
        
        DelayLengthUpperLimit = {'100','150'};
        InitialCondition = {'0.0','0.5'};
        ExternalReset = {'None','Rising','Falling','Either',...
            'Level','Level hold'};
        InputProcessing = {'Columns as channels (frame based)',...
            'Elements as channels (sample based)','Inherited'};
        UseCircularBuffer = {'off', 'on'};
        PreventDirectFeedthrough = {'off', 'on'};
        RemoveDelayLengthCheckInGeneratedCode = {'off', 'on'};
        DiagnosticForDelayLength = {'None','Warning','Error'};
        SampleTime = {'-1'};
        StateName = {''};
        StateMustResolveToSignalObject = {'off', 'on'};
        StateSignalObject = {};
        StateStorageClass = {'Auto','Model default','ExportedGlobal',...
            'ImportedExtern','ImportedExternPointer','Custom'};
        CodeGenStateStorageTypeQualifier = {''};
       
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
%                     inpDataType = s.inputDataType;
%                     s = rmfield(s,'inputDataType');
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
                    
                    dim_Idx = mod(i, length(fstInDims)) + 1;
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
            for pDelayLength = 1 : numel(obj.DelayLength)
                for pInitialCondition = 1 : numel(obj.InitialCondition)
                    s = struct();
                    s.InitialCondition = obj.InitialCondition{pInitialCondition};
                    s.DelayLength = obj.DelayLength{pDelayLength};
                    params{end+1} = s;
                end
            end
        end

    end
end

