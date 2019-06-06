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
            'Holding final value','Cyclic repetition'};
    end
    
    properties
        % other properties
        OutDataTypeStr = {...
            'fixdt(''double'')', ...
             'Inherit: auto',...
            'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32'};
        ZeroCross = {'off', 'on'};
        SampleTime = {'0'};
        
    end
    methods
        function status = generateTests(obj, outputDir)
            status = 0;
            params = obj.getParams();
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
                    blkParams = Block_Test.struct2blockParams(s);
                    add_block(obj.blkLibPath, blkPath, blkParams{:});
                    Block_Test.connectBlockToInportsOutports(blkPath);
                    
                    % store data in model work space
                    hws = get_param(mdl_name, 'modelworkspace');
                    X_matrix = [1 2; 3 4 ;5 6];
                    X_timeseries = timeseries(rand(5,1),[1 2 3 4 5]);
                    X_structure.time = [1 2 3 4 5 6];
                    X_structure.values = [11 12 13 14 15 16];
                    if ~strcmp(s.OutDataTypeStr,'Inherit: auto')
                        X_matrix = cast(X_matrix,s.OutDataTypeStr);
                        %X_timeseries = cast(X_timeseries,s.OutDataTypeStr);
                        %X_structure = cast(X_structure,s.OutDataTypeStr);                    
                    end
                    % cast data if OutDataTypeStr not compatible with
                    % double

                    hws.assignin('X_matrix', X_matrix);
                    hws.assignin('X_timeseries', X_timeseries);
                    hws.assignin('X_structure', X_structure);
%                     code = 'X_data = [1 2 3;4 5 6];';
%                     set_param(mdl_name, 'PreLoadFcn', code);                    
                    % set model configuration parameters
                    configSet = getActiveConfigSet(mdl_name);
                    set_param(configSet, 'Solver', 'FixedStepDiscrete');
                    
                    failed = CompileModelCheck_pp( mdl_name );
                    if failed
                        display(s);
                        display_msg(['Model failed: ' mdl_name], ...
                            MsgType.ERROR, 'generateTests', '');
                        save_system(mdl_name, mdl_path);  % to open and see what's wrong
                    else
                        %save_system(mdl_name, mdl_path);
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
                
                %ZeroCross: not used
                
                %SampleTime: not used
                
                params2{i1} = s;
            end
        end
        function params = getPermutations(obj)
            params = {};
            for i1=1:length(obj.VariableName)
                s = struct();
                s.VariableName = obj.VariableName{i1};                
                for i2=1:length(obj.Interpolate)
                    s.Interpolate = obj.Interpolate{i2};
                    for i3=1:length(obj.OutputAfterFinalValue)
                        s.OutputAfterFinalValue = obj.OutputAfterFinalValue{i3};   
                        if i2==1 && i3==1  % if Interpolate is 'off', 
                            if(mod(i1,2)==0)
                                s.OutputAfterFinalValue = ...
                                    obj.OutputAfterFinalValue{2}; % set to 0
                            else
                                s.OutputAfterFinalValue = ...
                                    obj.OutputAfterFinalValue{3}; % hold last value
                            end
                        end
                        params{end+1} = s;
                    end
                end
            end
        end
    end
end

