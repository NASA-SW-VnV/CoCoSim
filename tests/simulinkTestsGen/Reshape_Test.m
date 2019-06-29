classdef Reshape_Test < Block_Test
    %Reshape_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Reshape_TestGen';
        blkLibPath = 'simulink/Math Operations/Reshape';
    end
    
    properties
        % properties that will participate in permutations
        OutputDimensionality = {'1-D array','Column vector (2-D)',...
            'Row vector (2-D)','Customize','Derive from reference input port'};
        OutputDimensions =  {'[1,2]','[2,1]','[2,3]','[2,3,4]'};
        inputDimension = {'[1,2]','[2,1]','[2,3]','[2,3,4]','[2,3,4,2]'};
    end
    
    properties
        % other properties

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
                    inpDimension = s.inputDimension;
                    s = rmfield(s,'inputDimension');
                                        
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
                    
                    for inPort = 1:numel(inport_list)
                        set_param(inport_list{inPort}, 'PortDimensions', inpDimension);
                    end
                    
                    % if vector, alternate between row and column vector
                    

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
            for pOutpDimensionality = 1 : numel(obj.OutputDimensionality) 
                for pInputDims = 1 : numel( obj.inputDimension )
                    s = struct();
                    s.OutputDimensionality = obj.OutputDimensionality{pOutpDimensionality};
                    s.inputDimension = obj.inputDimension{pInputDims};
                    if pOutpDimensionality == 4
                        s4 = s;
                        for pOutDims = 1:numel(obj.OutputDimensions)
                            s4.OutputDimensions = ...
                                obj.OutputDimensions{pOutDims};
                            params{end+1} = s4;
                        end
                    else
                        params{end+1} = s;
                    end

                end
                
            end
        end

    end
end

