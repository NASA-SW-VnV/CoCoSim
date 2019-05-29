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
        function status = generateTests(obj, outputDir)
            status = 0;
            params = obj.getParams();
            fstInDims = {'1', '1', '3', '[2,3]'};
            for i=1 : length(params)
                try
                    s = params{i};
                    mdl_name = sprintf('%s%d', obj.fileNamePrefix, i);
                    try
                        if bdIsLoaded(mdl_name), bdclose(mdl_name); end
                        mdl_path = fullfile(outputDir, strcat(mdl_name, '.slx'));
                        if exist(mdl_path, 'file')
                            delete(mdl_path);
                            %continue;
                        end
                    catch
                        continue;
                    end
                    new_system(mdl_name);
                    
                    blkPath = fullfile(mdl_name, 'P');
                    
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
                    
                    blkParams = Block_Test.struct2blockParams(s);
                    add_block(obj.blkLibPath, blkPath, blkParams{:});
                    Block_Test.connectBlockToInportsOutports(blkPath);
                    
                    % go over inports
                    inport_list = find_system(mdl_name, ...
                        'SearchDepth',1, 'BlockType','Inport');
                    
                    % Inport 1: test if the block behaves as scalar function.
                    dim_Idx = mod(i, length(fstInDims)) + 1;
                    set_param(inport_list{1},...
                        'PortDimensions', fstInDims{dim_Idx}, ...
                        'OutMin', num2str(BPMin), ...
                        'OutMax', num2str(BPMax));
                    
                    % Inport 2: replace Inport with constant for breakpoints inport
                    failed = PP2Utils.replace_one_block(inport_list{2},...
                        'simulink/Sources/Constant');
                    if ~failed
                        set_param(inport_list{2}, 'Value', xdat);
                    end
                    
                    % Inport 3: set dimension
                    set_param(inport_list{3}, 'PortDimensions', ...
                        mat2str(tableDim));
                    
                    
                    % set model configuration parameters
                    configSet = getActiveConfigSet(mdl_name);
                    set_param(configSet, 'Solver', 'FixedStepDiscrete');
                    
                    failed = CompileModelCheck_pp( mdl_name );
                    if failed
                        display(s);
                        display_msg(['Model failed: ' mdl_name], ...
                            MsgType.ERROR, 'generateTests', '');
                    else
                        save_system(mdl_name, mdl_path);
                    end
                    bdclose(mdl_name);
                    
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
            for i=1:length(obj.LookUpMeth)
                s = struct();
                s.LookUpMeth = obj.LookUpMeth{i};
                for d = 1:2
                    % xdat and ydat can be 1 or 2 dimensional
                    if d == 1
                        B = MatlabUtils.construct_random_doubles(1, 0, 127, [5 1]);
                        s.BPMin = min(B(:));
                        s.BPMax = max(B(:));
                        s.xdat = mat2str(sort(B));
                        s.TableDim = 5;
                    else
                        B = MatlabUtils.construct_random_doubles(1, 0, 127, [3, 5]);
                        s.BPMin = min(B(:));
                        s.BPMax = max(B(:));
                        s.xdat = mat2str(reshape(sort(B(:)), [3, 5]));
                        s.TableDim = [3, 5];
                    end
                    params{end+1} = s;
                end
            end
        end
    end
end

