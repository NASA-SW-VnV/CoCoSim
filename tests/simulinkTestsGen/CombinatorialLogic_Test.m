classdef CombinatorialLogic_Test < Block_Test
    %CombinatorialLogic_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'CombinatorialLogic_TestGen';
        blkLibPath = sprintf('simulink/Logic and Bit Operations/Combinatorial \nLogic');
    end
    
    properties
        % properties that will participate in permutations
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
            if condExecSSPeriod <= 1
                condExecSSPeriod = max(4, floor(nb_tests/3));
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
                    
                    for inp = 1:length(inport_list)
                        % rotate over input data type
                        set_param(inport_list{inp}, ...
                            'OutDataTypeStr',inpDataType, ...
                            'OutMin', '0', ...
                            'OutMax', '1');
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
        
        function params = getParams(obj)
            params = {};
            nb_inputs = {1, 2, 3, 4};
            nb_columns = {1. 2. 3};
            is_boolean = false;
            i_nb_columns = 0;
            
            for i = 1:length(nb_inputs)
                s = struct();
                i_nb_columns = mod(i_nb_columns, length(nb_columns)) + 1;
                nb_rows = 2^nb_inputs{i};
                c = nb_columns{i_nb_columns};
                is_boolean = not(is_boolean);
                if is_boolean
                    s.inputDataType = 'boolean';
                    M = MatlabUtils.construct_random_integers(1, 0, 1, 'uint8', [nb_rows,c]);
                else
                    s.inputDataType = 'boolean';
                    M = MatlabUtils.construct_random_doubles(1, 0, 1, [nb_rows,c]);
                end
                s.TruthTable = mat2str(M);
                params{end+1} = s;
            end
            
        end
        
    end
end

