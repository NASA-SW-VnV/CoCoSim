classdef Gain_Test < Block_Test
    %Gain_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Gain_TestGen';
        blkLibPath = 'simulink/Math Operations/Gain';
    end
    
    properties
        % properties that will participate in permutations
        Gain = {'-1','1','1.6'};
        Multiplication = {'Element-wise(K.*u)','Matrix(K*u)',...
            'Matrix(u*K)','Matrix(K*u) (u vector)'};
        OutDataTypeStr = {...
            'double','single','int8','uint8','int16','uint16','int32',...
            'uint32'};
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32'};   
    end
    
    properties
        % other properties
        SampleTime = {'1'};
        OutMin = {'0.','1.'};
        OutMax = {'10','100'};        
        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', ...
            'Round', 'Simplest', 'Zero'};
        SaturateOnIntegerOverflow = {'off', 'on'};
        LockScale = {'off','on'};
        ParamMin = {[]};
        ParamMax = {[]};
        ParamDataTypeStr = {'Inherit: Inherit via internal rule',...
            'Inherit: Same as input','double','single','int8','uint8',...
            'int16','uint16','int32','uint32'};
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
                    inputDimension = s.inputDimension;
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
                    
                    %set input dimension
                    set_param(inport_list{1}, ...
                        'PortDimensions', inputDimension);

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
            for pOutDataTypeStr = 1 : numel(obj.OutDataTypeStr)
                for pMultiplication = 1 : numel(obj.Multiplication)
                    pOutMin = ...
                        mod(length(params), ...
                        length(obj.OutMin))...
                        + 1;
                    pRndMeth = mod(length(params), ...
                        length(obj.RndMeth))+ 1;
                    pParamDataTypeStr = mod(length(params), ...
                        length(obj.ParamDataTypeStr))+ 1;
                    s = struct();
                    s.Gain = '[1 2 3;4 5 6]';   
                    if pMultiplication==1      % 'Element-wise(K.*u)'
                        s.inputDimension = '[2,3]';
                    elseif pMultiplication==2  %  'Matrix(K*u)'
                        s.inputDimension = '[3,2]';
                    elseif pMultiplication==3  % 'Matrix(u*K)'
                        s.inputDimension = '[3,2]';
                    else % pMultiplication==4   'Matrix(K*u) (u vector)'
                        s.inputDimension = '[1,3]';
                    end
                    s.Multiplication = obj.Multiplication{pMultiplication};
                    s.OutDataTypeStr = obj.OutDataTypeStr{pOutDataTypeStr};
                    s.OutMin = obj.OutMin{pOutMin};
                    s.OutMax = obj.OutMax{pOutMin};                    
                    s.RndMeth = obj.RndMeth{pRndMeth};
                    s.SaturateOnIntegerOverflow = ...
                        obj.SaturateOnIntegerOverflow{pOutMin};
                    s.LockScale = obj.LockScale{pOutMin};
                    s.ParamDataTypeStr = ...
                        obj.ParamDataTypeStr{pParamDataTypeStr};
                    params{end+1} = s;
                end
            end
        end

    end
end

