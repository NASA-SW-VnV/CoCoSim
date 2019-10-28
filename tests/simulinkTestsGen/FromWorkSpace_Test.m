classdef FromWorkSpace_Test < Block_Test
    %FROMWORKSPACE_TEST generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'fromWorkSpace_TestGen';
        blkLibPath = 'simulink/Sources/From Workspace';
    end
    
    properties
        % properties that will participate in permutations
        VariableName = {'X_matrix','X_timeseries','X_structure'};
        Interpolate = {'off', 'on'};
        OutputAfterFinalValue = {'Extrapolation','Setting to zero',...
            'Holding final value'};% We do not support,'Cyclic repetition'};
    end
    
    properties
        % other properties
        OutDataTypeStr = {...
            'Inherit: auto',...
            'double', 'single', 'int8', 'uint8', 'Inherit: auto', 'uint16', ...
            'int32','Inherit: auto', 'boolean'};
        ZeroCross = {'off', 'on'};
        SampleTime = {'-1'};
        
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
                    %% add variables to model workspace if needed
                    % store data in model work space
                    hws = get_param(mdl_name, 'modelworkspace');
                    
                    if isfield(s, 'M')
                        M = s.M;
                        s = rmfield(s, 'M');
                    end
                    
                    if ~strcmp(s.OutDataTypeStr,'Inherit: auto')
                        if strcmp(s.OutDataTypeStr, 'boolean')
                            dt = 'logical';
                        else
                            dt = s.OutDataTypeStr;
                        end
                        if isa(M, 'timeseries')
                            M.Data = cast(M.Data, dt);
                        elseif isa(M, 'struct')
                            M.signals.values = cast(M.signals.values, dt);
                        end
                    end
                    
                    hws.assignin(s.VariableName, M);
                    
                    %% add the block
                    Block_Test.add_and_connect_block(obj.blkLibPath, blkPath, s);
                    
                    
                    %% set model configuration parameters and save model if it compiles
                    Block_Test.setConfigAndSave(mdl_name, mdl_path);
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
                if ~strcmp(s.VariableName, obj.VariableName{1})
                    %OutDataTypeStr
                    idx = mod(i1, length(obj.OutDataTypeStr)) + 1;
                    s.OutDataTypeStr = obj.OutDataTypeStr{idx};
                else
                    s.OutDataTypeStr = obj.OutDataTypeStr{1};% 'Inherit: auto'
                end
                idx = mod(i1, length(obj.ZeroCross)) + 1;
                s.ZeroCross = obj.ZeroCross{idx};
                
                s.SampleTime = '-1';
                
                params2{i1} = s;
            end
        end
        function params = getPermutations(obj)
            params = {};
            t = 0.2 * [0:49]';
            x = sin(t);
            y = cos(t);
            z = 10*cos(t);
            dim_idx = 1;
            for i1=1:length(obj.VariableName)
                s = struct();
                s.VariableName = obj.VariableName{i1};
                
                for i2=1:length(obj.Interpolate)
                    s.Interpolate = obj.Interpolate{i2};
                    
                    for i3=1:length(obj.OutputAfterFinalValue)
                        if i2==1 && i3==1  % if Interpolate is 'off',
                            s.OutputAfterFinalValue = ...
                                obj.OutputAfterFinalValue{i2+1};
                        else
                            s.OutputAfterFinalValue = obj.OutputAfterFinalValue{i3};
                        end
                        
                        if i1 == 1
                            % Matrix
                            if dim_idx == 1
                                % one dimension
                                s.M = [t, x];
                            elseif dim_idx == 2
                                % two dimensions
                                s.M = [t, x, y];
                            elseif dim_idx == 3
                                % 3 dimensions
                                s.M = [t, x, y, z];
                            end
                        elseif i1 == 2
                            %timeseries
                            if dim_idx == 1
                                % one dimension
                                s.M = timeseries(rand(1,length(t)), t);
                            elseif dim_idx == 2
                                % two dimensions
                                s.M = timeseries(rand(2, 3,length(t)), t);
                            elseif dim_idx == 3
                                % 3 dimensions
                                s.M = timeseries(rand(2, 3, 4,length(t)), t);
                                
                            end
                        else
                            %struct
                            % one dimension
                            if dim_idx == 1
                                wave.time = t;
                                wave.signals.values = x;
                                wave.signals.dimensions =1;
                                s.M = wave;
                            elseif dim_idx == 2
                                % two dimensions
                                wave.time = t;
                                wave.signals.values = [x, y];
                                wave.signals.dimensions =2;
                                s.M = wave;
                            elseif dim_idx == 3
                                % 3 dimensions
                                wave.time = t;
                                wave.signals.values = [x, y, z];
                                wave.signals.dimensions = 3;
                                s.M = wave;
                            end
                        end
                        params{end+1} = s;
                        dim_idx = dim_idx + 1;
                        if dim_idx > 3
                            dim_idx = 1;
                        end
                    end
                end
            end
        end
    end
end

