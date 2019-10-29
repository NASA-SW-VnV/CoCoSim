classdef DiscreteZeroPole_Test < Block_Test
    %DiscreteZeroPole_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'DiscreteZeroPole_TestGen';
        blkLibPath = 'simulink/Discrete/Discrete Zero-Pole';
    end
    
    properties
        % properties that will participate in permutations
        Zeros = {'[1.0 2.0]'};
        Poles = {'[0 0.5 1.]'}; 
        Gain = {'0.5'}; 
        OutDataTypeStr = {...
            'double','single','int8','uint8','int16','uint16','int32',...
            'uint32','boolean'};
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32','boolean'};   
    end
    
    properties
        % other properties
        SampleTime = {'1'};
        StateName = {''};
        StateMustResolveToSignalObject = {'off','on'};
        StateSignalObject = {};
        StateStorageClass = {'Auto','Model default','ExportedGlobal',...
            'ImportedExtern','ImportedExternPointer','Custom'};
        RTWStateStorageTypeQualifier = {''};
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
            for pZeros = 1 : numel(obj.Zeros)
                for pPoles = 1 : numel(obj.Poles)
                    pStateMustResolveToSignalObject = ...
                        mod(length(params), ...
                        length(obj.StateMustResolveToSignalObject))...
                        + 1;
                    pStateStorageClass = mod(length(params), ...
                        length(obj.StateStorageClass))+ 1;
                    s = struct();
                    s.Poles = obj.Poles{pPoles};
                    s.Zeros = obj.Zeros{pZeros};
%                     s.StateMustResolveToSignalObject = ...
%                         obj.StateMustResolveToSignalObject(...
%                         pStateMustResolveToSignalObject);
                    s.StateStorageClass = ...
                        obj.StateStorageClass{pStateStorageClass};
                    s.Gain = obj.Gain{1};
                    params{end+1} = s;
                end
            end
        end

    end
end

