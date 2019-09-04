classdef DiscreteStateSpace_Test < Block_Test
    %DiscreteStateSpace_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'DiscreteStateSpace_TestGen';
        blkLibPath = 'simulink/Discrete/Discrete State-Space';
    end
    
    properties
        % properties that will participate in permutations
        % A must be an n-by-n matrix, where n is the number of states.
        % B must be an n-by-m matrix, where m is the number of inputs.
        % C must be an r-by-n matrix, where r is the number of outputs.
        % D must be an r-by-m matrix.
        n = [1,2];
        m = [1,2];
        r = [1,2];
        A = {mat2str(1.),mat2str([0.5 1.]);...
            mat2str([1.; .2]),mat2str([.5 .6; .7 .8])};
        B = {mat2str(1.),mat2str([0.5 1.]);...
            mat2str([1.; .2]),mat2str([.5 .6; .7 .8])};
        C = {mat2str(1.),mat2str([0.5 1.]);...
            mat2str([1.; .2]),mat2str([.5 .6; .7 .8])};
        D = {mat2str(1.),mat2str([0.5 1.]);...
            mat2str([1.; .2]),mat2str([.5 .6; .7 .8])};
        InitialCondition =  {'0'};
        OutDataTypeStr = {'Inherit: Inherit via internal rule',...
            'int8','int16','int32','fixdt(1,16,0)'};
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32','boolean','fixdt(1,16,0)','fixdt(1,16,2^0,0)'};   
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
            for pn = 1 : numel(obj.n)
                for pm = 1 : numel(obj.m)
                    for pr = 1 : numel(obj.r)                        
                        for pInitialCondition = 1 : numel(obj.InitialCondition)
%                             pStateMustResolveToSignalObject = ...
%                                 mod(length(params), ...
%                                 length(obj.StateMustResolveToSignalObject))...
%                                 + 1;
%                             pStateStorageClass = mod(length(params), ...
%                                 length(obj.StateStorageClass))+ 1;
                            s = struct();
                            s.A = obj.A{pn,pn};                            
                            s.B = obj.B{pn,pm};
                            s.C = obj.C{pr,pn};
                            s.D = obj.D{pr,pm};
                            s.InitialCondition = ...
                                obj.InitialCondition{pInitialCondition};
%                             s.StateMustResolveToSignalObject = ...
%                                 obj.StateMustResolveToSignalObject(...
%                                 pStateMustResolveToSignalObject);
%                             s.StateStorageClass = obj.StateStorageClass(...
%                                 pStateStorageClass);
                            params{end+1} = s;
                        end                        
                    end
                end
            end
        end

    end
end

