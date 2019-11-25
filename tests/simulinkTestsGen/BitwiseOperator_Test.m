classdef BitwiseOperator_Test < Block_Test
    %BitwiseOperator_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'BitwiseOperator_TestGen';
        blkLibPath = 'simulink/Logic and Bit Operations/Bitwise Operator';
    end
    
    properties
        % properties that will participate in permutations
        inputDataType = {'int8','uint8','int16', 'uint16', 'int32', 'uint32'};
        logicop = {'AND','OR','NAND','NOR','XOR','NOT'};
        UseBitMask = {'on','off'};
        BitMaskRealWorld = {'Real World Value','Stored Integer'};
        NumInputPorts = {'1','2','3'};
        %BitMask = {'bin2dec('11011001')'};
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
                    inpDataType = s.inputDataType;
                    s = rmfield(s,'inputDataType');
                    inputDims  = s.inputDims;
                    s = rmfield(s,'inputDims');
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
            inpIsIntCount = 0;
            for pOperator = 1 : numel(obj.logicop)
                for pUseBitMask = 1:numel(obj.UseBitMask)
                    for pTreatMask = 1:numel(obj.BitMaskRealWorld)
                        for pNumInputPorts = 1:numel(obj.NumInputPorts)
                                % rotate inputDataType
                                pInputDataType = mod(numel(params), ...
                                    length(obj.inputDataType)) + 1;
                                if strfind(obj.inputDataType{pOperator}, 'int')
                                    inpIsIntCount = inpIsIntCount + 1;
                                end
                                s = struct();
                                s.logicop = obj.logicop{pOperator};
                                s.UseBitMask = obj.UseBitMask{pUseBitMask};
                                s.BitMaskRealWorld = obj.BitMaskRealWorld{pTreatMask};
                                s.inputDataType = obj.inputDataType{pInputDataType};
                                if strfind(s.logicop, 'NOT')
                                    s.NumInputPorts = '1';
                                else
                                    s.NumInputPorts = obj.NumInputPorts{pNumInputPorts};
                                end
                                s.inputDims = '1';
                                params{end+1} = s;
                                if pInputDataType == 1   % scalar bias, add different input dims
                                    s.inputDims = '[1 3]';
                                    params{end+1} = s;
                                    s.inputDims = '[2 2]';
                                    params{end+1} = s;
                                elseif pInputDataType == 2
                                    s.inputDims = '[1 3]';
                                    params{end+1} = s;
                                    %                         s.inputDims = '[3 1]';
                                    %                         params{end+1} = s;
                                elseif pInputDataType == 3
                                    s.inputDims = '[2 2]';
                                    params{end+1} = s;
                                end
                        end
                    end
                end
            end
            
        end

    end
end

