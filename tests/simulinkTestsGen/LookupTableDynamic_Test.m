classdef LookupTableDynamic_Test < Block_Test
    %LOOKUPTABLEDYNAMIC_TEST generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'lookupTableDynamic_TestGen';
        blkLibPath = 'simulink/Lookup Tables/Lookup Table Dynamic';
    end
    
    properties
        % properties that will participate in permutations
        LookUpMeth = {'Interpolation-Extrapolation', ...
            'Interpolation-Use End Values', 'Use Input Nearest', ...
            'Use Input Below', 'Use Input Above'};
        % not block specific parameters
        inputDataType = {'double', 'single', 'int8', ...
            'uint8', 'int16', 'uint16', ...
            'int32', 'uint32'};
    end
    
    properties
        % other properties
        OutDataTypeStr = {...
            'fixdt(''double'')', ...
            'Inherit: Inherit via back propagation',...
            'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32'};
        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', 'Round', 'Simplest', 'Zero'};
        DoSatur = {'off', 'on'};
        
    end
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();
            fstInDims = {'1', '1', '3', '[2,3]'};
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
                    tableDim = 1;
                    if isfield(s, 'TableDim')
                        tableDim = s.TableDim;
                        s = rmfield(s, 'TableDim');
                    end
                    
                    BPMin = 0;
                    if isfield(s, 'BPMin')
                        BPMin = s.BPMin - 2;
                        s = rmfield(s, 'BPMin');
                    end
                    BPMax = 127;
                    if isfield(s, 'BPMax')
                        BPMax = s.BPMax + 2;
                        s = rmfield(s, 'BPMax');
                    end
                    
                    xdat = '';
                    if isfield(s, 'xdat')
                        xdat = s.xdat;
                        s = rmfield(s, 'xdat');
                    end
                    
                    inputType = s.inputDataType;
                    s = rmfield(s, 'inputDataType');
                    
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
                    
                    % Inport 1: test if the block behaves as scalar function.
                    dim_Idx = mod(i, length(fstInDims)) + 1;
                    % OutMin and OutMax has to respect data type
                    if startsWith(inputType, 'uint')
                        BPMin = max(BPMin,0);
                    end
                    if contains(inputType, 'int')
                        maxClassname = intmax(inputType);
                        BPMax = num2str(min(BPMax, maxClassname));
                    end
                    
                    set_param(inport_list{1},...
                        'PortDimensions', fstInDims{dim_Idx}, ...
                        'OutDataTypeStr', inputType, ...
                        'OutMin', num2str(BPMin), ...
                        'OutMax', num2str(BPMax));
                    
                    % Inport 2: replace Inport with constant for breakpoints inport
                    failed = PP2Utils.replace_one_block(inport_list{2},...
                        'simulink/Sources/Constant');
                    if ~failed
                        set_param(inport_list{2}, ...
                            'OutDataTypeStr', inputType, ...
                            'Value', xdat);
                    end
                    
                    % Inport 3: set dimension
                    set_param(inport_list{3}, 'PortDimensions', ...
                        mat2str(tableDim));
                    
                    
                    %% set model configuration parameters and save model if it compiles
                    Block_Test.setConfigAndSave(mdl_name, mdl_path);
                    
                catch me
                    display_msg(me.getReport(), MsgType.ERROR, 'generateTests', '');
                    display(s);
                    display_msg(['Model failed: ' mdl_name], ...
                        MsgType.DEBUG, 'generateTests', '');
                    
                    bdclose(mdl_name)
                end
            end
        end
        function params2 = getParams(obj)
            
            params1 = obj.getPermutations();
            params2 = cell(1, length(params1));
            for i1 = 1 : length(params1)
                s = params1{i1};
                %OutDataTypeStr
                idx = mod(i1, length(obj.OutDataTypeStr)) + 1;
                s.OutDataTypeStr = obj.OutDataTypeStr{idx};
                
                %RndMeth
                idx = mod(i1, length(obj.RndMeth)) + 1;
                s.RndMeth = obj.RndMeth{idx};
                
                %SaturateOnIntegerOverflow
                idx = mod(i1, length(obj.DoSatur)) + 1;
                s.DoSatur = obj.DoSatur{idx};
                
                params2{i1} = s;
            end
        end
        function params = getPermutations(obj)
            params = {};
            for pLookUpMethog=1:length(obj.LookUpMeth)
                s = struct();
                s.LookUpMeth = obj.LookUpMeth{pLookUpMethog};
                for pInputType = 1:numel(obj.inputDataType)
                    s.inputDataType = obj.inputDataType{pInputType};
                    B = MatlabUtils.construct_random_doubles(1, 0, 127, [5 1]);
%                     if pInputType==1
%                         B = MatlabUtils.construct_random_doubles(1, 0, 127, [5 1]);
%                     else
%                         B = [0, 2, 5, 8, 20];
%                     end
                    
                    s.BPMin = min(B(:));
                    s.BPMax = max(B(:));
                    s.xdat = mat2str(sort(B));
                    s.TableDim = 5;
                    params{end+1} = s;
                end
            end
        end
    end
end

