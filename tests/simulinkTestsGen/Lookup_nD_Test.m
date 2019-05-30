classdef Lookup_nD_Test < Block_Test
    %Lookup_nD_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'lookup_nD_TestGen';
        blkLibPath = 'simulink/Lookup Tables/n-D Lookup Table';
    end
    
    properties
        % properties that will participate in permutations
        NumberOfTableDimensions = {'1', '2', '3', '4', '5', '6', '7'};
        DataSpecification = {'Table and breakpoints','Table and breakpoints', 'Lookup table object'};
        Table = '';
        LookupTableObject = 'LUTObj';
        BreakpointsSpecification ={'Explicit values', 'Even spacing'};
        BreakpointsForDimension1FirstPoint = '' ; % change 1 by k from 1 to n (nb dimension)
        BreakpointsForDimension1Spacing = '';% change 1 by k from 1 to n (nb dimension)
        BreakpointsForDimension1 = '';% change 1 by k from 1 to n (nb dimension)
        
        InterpMethod = {'Flat' , 'Nearest' , 'Linear' };% 'Cubic spline' is not supported
        ExtrapMethod = {'Clip', 'Linear'};% 'Cubic spline' is not supported
        UseLastTableValue =  {'off', 'on'};
    end
    
    properties
        % other properties
        UseOneInputPortForAllInputData = {'off', 'off', 'on'};
        TableDataTypeStr = {'Inherit: Same as output',...
            'Inherit: Same as output',...
            'Inherit: Same as output',...
            'Inherit: Same as output',...
            'Inherit: Same as output',...
            'Inherit: Inherit from ''Table data''',...
            'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32'};
        BreakpointsForDimension1DataTypeStr = {...% change 1 by k from 1 to n (nb dimension)
            'Inherit: Same as corresponding input',...
            'Inherit: Inherit from ''Breakpoint data''',...
            'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32'};
        FractionDataTypeStr = {'Inherit: Inherit via internal rule',...
            'double' , 'single' };
        IntermediateResultsDataTypeStr = {...
            'Inherit: Inherit via internal rule', 'Inherit: Same as output',...
            'Inherit: Inherit via internal rule', 'Inherit: Same as output',...
            'Inherit: Inherit via internal rule', 'Inherit: Same as output',...
            'Inherit: Inherit via internal rule', 'Inherit: Same as output',...
            'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32'};
        TableMin = {'[]'};
        TableMax = {'[]'};
        OutDataTypeStr = {...
            'Inherit: Inherit via back propagation', 'Inherit: Inherit from table data',...
            'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32'};
        OutMin = {'[]'};
        OutMax = {'[]'};
        InternalRulePriority = {'Speed', 'Precision'};
        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', 'Round', 'Simplest', 'Zero'};
        SaturateOnIntegerOverflow = {'off', 'on'};
    end
    
    methods
        function status = generateTests(obj, outputDir)
            status = 0;
            params = obj.getParams();
            fstInDims = {'1', '1', '1', '1', '1', '3', '[2,3]'};
            for i=1 : length(params)
                try
                    s = params{i};
                    mdl_name = sprintf('%s%d', obj.fileNamePrefix, i);
                    try
                        if bdIsLoaded(mdl_name), bdclose(mdl_name); end
                        mdl_path = fullfile(outputDir, strcat(mdl_name, '.slx'));
                        if exist(mdl_path, 'file')
                            %delete(mdl_path);
                            continue;
                        end
                    catch
                        continue;
                    end
                    new_system(mdl_name);
                    
                    hws = get_param(mdl_name, 'modelworkspace');
                    blkPath = fullfile(mdl_name, 'P');
                    
                    if isfield(s, 'LUTObj')
                        hws.assignin('LUTObj', s.LUTObj);
                        s = rmfield(s, 'LUTObj');
                        obj.addLookupTableObjectToBaseWs(mdl_name)
                    end
                    tableDim = 1;
                    if isfield(s, 'TableDim')
                        tableDim = s.TableDim;
                        s = rmfield(s, 'TableDim');
                    end
                    
                    
                    blkParams = Block_Test.struct2blockParams(s);
                    add_block(obj.blkLibPath, blkPath, blkParams{:});
                    Block_Test.connectBlockToInportsOutports(blkPath);
                    
                    % go over inports
                    inport_list = find_system(mdl_name, ...
                        'SearchDepth',1, 'BlockType','Inport');
                    nbInpots = length(inport_list);
                    
                    if strcmp(s.UseOneInputPortForAllInputData, 'on')
                        set_param(inport_list{1}, 'PortDimensions', ...
                            num2str(length(tableDim)));
                    else
                        for inpIdx = 1:nbInpots
                            set_param(inport_list{inpIdx},...
                                'OutMin', '0', 'OutMax', '127');
                        end
                        % test if the block behaves as scalar function.
                        dim_Idx = mod(i, length(fstInDims)) + 1;
                        set_param(inport_list{1}, 'PortDimensions', ...
                            fstInDims{dim_Idx});
                    end
                    
                    
                    
                    
                    % set model configuration parameters
                    configSet = getActiveConfigSet(mdl_name);
                    set_param(configSet, 'Solver', 'FixedStepDiscrete');
                    set_param(configSet, 'ParameterOverflowMsg', 'none');
                    
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
                %UseOneInputPortForAllInputData
                idx = mod(i1, length(obj.UseOneInputPortForAllInputData)) + 1;
                s.UseOneInputPortForAllInputData = obj.UseOneInputPortForAllInputData{idx};
                
                if strcmp(s.ExtrapMethod, 'Linear')
                    %extrapolate only when all the input,
                    %output, fraction, intermediate, table
                    %and breakpoint data types are the same
                    %floating-point type
                    params2{i1} = s;
                    continue
                end
                            
                
                if strcmp(s.InterpMethod, 'Linear') || strcmp(s.ExtrapMethod, 'Linear')
                    %IntermediateResultsDataTypeStr
                    idx = mod(i1, length(obj.IntermediateResultsDataTypeStr)) + 1;
                    s.IntermediateResultsDataTypeStr = obj.IntermediateResultsDataTypeStr{idx};
                    
                    idx = mod(i1, length(obj.FractionDataTypeStr)) + 1;
                    s.FractionDataTypeStr = obj.FractionDataTypeStr{idx};
                end
                %OutDataTypeStr
                idx = mod(i1, length(obj.OutDataTypeStr)) + 1;
                s.OutDataTypeStr = obj.OutDataTypeStr{idx};
                
                %RndMeth
                idx = mod(i1, length(obj.RndMeth)) + 1;
                s.RndMeth = obj.RndMeth{idx};
                
                %SaturateOnIntegerOverflow
                idx = mod(i1, length(obj.SaturateOnIntegerOverflow)) + 1;
                s.SaturateOnIntegerOverflow = obj.SaturateOnIntegerOverflow{idx};
                
                params2{i1} = s;
            end
        end
        
        
        function params = getPermutations(obj)
            params = {};
            i11= 0;
            i5 = 0;
            i2 = 0;
            for i1 = 1 : 7
                s = struct();
                s.NumberOfTableDimensions = num2str(i1);
                
                for i3 = 1 : length ( obj.InterpMethod )
                    s.InterpMethod = obj.InterpMethod{i3};
                    
                    for i4 = 1 : length ( obj.ExtrapMethod )
                        s.ExtrapMethod = obj.ExtrapMethod{i4};
                        
                        i2 = mod(i2 , length( obj.DataSpecification )) + 1;
                        s.DataSpecification = obj.DataSpecification{i2};
                        
                        if i4 == 1 % clip
                            %UseLastTableValue
                            i11 = mod(i11, 2) + 1;
                            s.UseLastTableValue =  obj.UseLastTableValue{i11};
                        end
                        
                        i5 = mod(i5 , length ( obj.BreakpointsSpecification )) + 1;
                        s2 = s;
                        s2.BreakpointsSpecification = obj.BreakpointsSpecification{i5};
                        
                        s3 = s2;
                        if i1 == 1
                            T = MatlabUtils.construct_random_doubles(1, 0, 127, [5 1]);
                            table = mat2str(T);
                            dim = 5;
                        elseif i1 == 2
                            dim = [3, 5];
                            T = MatlabUtils.construct_random_doubles(1, 0, 127, [3, 5]);
                            table = mat2str(T);
                        elseif i1 == 3
                            table = 'reshape(repmat([4 5 6 7 8;16 19 20 21 22;10 18 23 24 25],1,2),[2,5,3])';
                            dim = [2,5,3];
                        elseif i1 == 4
                            dim = [2, 5, 3, 2];
                            table = 'reshape(repmat([4 5 6 7 8;16 19 20 21 22;10 18 23 24 25],2,2),[2,5,3,2])';
                        elseif i1 == 5
                            table = 'reshape(repmat([4 5 6 7 8;16 19 20 21 22;10 18 23 24 25],6,2),[2,5,3,2,3])';
                            dim = [2, 5, 3, 2, 3];
                        elseif i1 == 6
                            dim = [2, 5, 3, 2, 3, 4];
                            table = 'reshape(repmat([4 5 6 7 8;16 19 20 21 22;10 18 23 24 25],6,8),[2,5,3,2,3, 4])';
                        else
                            dim = [2, 5, 3, 2, 3, 4, 3];
                            table = 'reshape(repmat([4 5 6 7 8;16 19 20 21 22;10 18 23 24 25],18,8),[2,5,3,2,3,4,3])';
                        end
                        
                        
                        s3.TableDim = dim;
                        
                        if strcmp(s3.ExtrapMethod, 'Linear')
                            %extrapolate only when all the input,
                            %output, fraction, intermediate, table
                            %and breakpoint data types are the same
                            %floating-point type
                            tableDataTypeStr = obj.TableDataTypeStr{1};
                            breakpointsForDimension1DataTypeStr = obj.BreakpointsForDimension1DataTypeStr{1};
                        else
                            idx = mod(i1, length(obj.TableDataTypeStr)) + 1;
                            tableDataTypeStr = obj.TableDataTypeStr{idx};
                            
                            if strcmp(s.InterpMethod, 'Nearest')
                                breakpointsForDimension1DataTypeStr = obj.BreakpointsForDimension1DataTypeStr{1};
                            else
                                idx = mod(i1, length(obj.BreakpointsForDimension1DataTypeStr)) + 1;
                                breakpointsForDimension1DataTypeStr = obj.BreakpointsForDimension1DataTypeStr{idx};
                            end
                        end
                        
                        if i5 == 1
                            %'Explicit values'
                            if i2 == 1
                                % Table and breakpoints
                                s3.Table = table;
                                s3.TableDataTypeStr = tableDataTypeStr;
                                
                                for d =1:length(dim)
                                    B = sort(MatlabUtils.construct_random_doubles(1, 0, 127, [dim(d) 1]));
                                    s3.(sprintf('BreakpointsForDimension%d', d)) = mat2str(B);
                                    s3.(sprintf('BreakpointsForDimension%dDataTypeStr', d)) = breakpointsForDimension1DataTypeStr;
                                end
                            else
                                s3.LookupTableObject = obj.LookupTableObject;
                                LUTObj = Simulink.LookupTable;
                                LUTObj.StructTypeInfo.Name =  'LUT';
                                LUTObj.Table.Value = eval(table);
                                if ~startsWith(tableDataTypeStr, 'Inherit')
                                    LUTObj.Table.DataType = tableDataTypeStr;
                                end
                                LUTObj.BreakpointsSpecification = obj.BreakpointsSpecification{i5};
                                for d =1:length(dim)
                                    LUTObj.Breakpoints(d).Value = sort(MatlabUtils.construct_random_doubles(1, 0, 127, [dim(d) 1]));
                                    if ~startsWith(breakpointsForDimension1DataTypeStr, 'Inherit')
                                        LUTObj.Breakpoints(d).DataType = breakpointsForDimension1DataTypeStr;
                                    end
                                end
                                s3.LUTObj = LUTObj;
                            end
                        else
                            %'Even spacing'
                            if i2 == 1
                                % Table and breakpoints
                                s3.Table = table;
                                s3.TableDataTypeStr = tableDataTypeStr;
                                for d =1:length(dim)
                                    B = MatlabUtils.construct_random_doubles(1, 0, 127, 1);
                                    s3.(sprintf('BreakpointsForDimension%dFirstPoint', d)) = num2str(B);
                                    s3.(sprintf('BreakpointsForDimension%dSpacing', d)) = '1.5';
                                    s3.(sprintf('BreakpointsForDimension%dDataTypeStr', d)) = breakpointsForDimension1DataTypeStr;
                                end
                            else
                                s3.LookupTableObject = obj.LookupTableObject;
                                LUTObj = Simulink.LookupTable;
                                LUTObj.StructTypeInfo.Name =  'LUT';
                                LUTObj.Table.Value = eval(table);
                                if ~startsWith(tableDataTypeStr, 'Inherit')
                                    LUTObj.Table.DataType = tableDataTypeStr;
                                end
                                LUTObj.BreakpointsSpecification = obj.BreakpointsSpecification{i5};
                                for d =1:length(dim)
                                    LUTObj.Breakpoints(d).FirstPoint = MatlabUtils.construct_random_doubles(1, 0, 127, 1);
                                    LUTObj.Breakpoints(d).Spacing = 1.5;
                                    if ~startsWith(breakpointsForDimension1DataTypeStr, 'Inherit')
                                        LUTObj.Breakpoints(d).DataType = breakpointsForDimension1DataTypeStr;
                                    end
                                end
                                s3.LUTObj = LUTObj;
                                
                            end
                        end
                        params{end+1} = s3;
                        
                        
                    end
                end
                
                
            end
            
        end
        
        function addLookupTableObjectToBaseWs(obj, mdl)
            code = get_param(mdl, 'PreLoadFcn');
            
            code = sprintf('%s\n hws = get_param(gcs, ''modelworkspace'');', code);
            code = sprintf('%s\n if hws.hasVariable(''LUTObj'')', code);
            code = sprintf('%s\n assignin(''base'',''LUTObj'', hws.getVariable(''LUTObj''));', code);
            code = sprintf('%s\n end', code);
            set_param(mdl, 'PreLoadFcn', code);
        end
    end
end

