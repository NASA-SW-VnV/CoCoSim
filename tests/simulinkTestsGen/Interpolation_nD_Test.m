classdef Interpolation_nD_Test < Block_Test
    %INTERPOLATION_ND_TEST generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'interpolation_nD_TestGen';
        blkLibPath = 'simulink/Lookup Tables/Interpolation Using Prelookup';
    end
    
    properties
        % properties that will participate in permutations
        NumberOfTableDimensions = {'1', '2', '3', '4'};
        TableSpecification = {'Explicit values', 'Lookup table object'};
        TableSource = {'Dialog', 'Input port'}; %Source
        Table = '';
        LookupTableObject = 'LUTObj';
        InterpMethod = {'Flat', 'Nearest', 'Linear'};
        ExtrapMethod = {'Clip', 'Linear'};
    end
    
    properties
        % other properties
        RequireIndexFractionAsBus = {'off', 'off', 'on'};
        ValidIndexMayReachLast = {'off', 'on'};
        NumSelectionDims = {'0', '0', '0', '0', '1', '2', '3'};
        TableDataTypeStr = {'Inherit: Same as output',...
            'Inherit: Same as output',...
            'Inherit: Same as output',...
            'Inherit: Same as output',...
            'Inherit: Same as output',...
            'Inherit: Inherit from ''Table data''',...
            'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32'};
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
                            delete(mdl_path);
                            %continue;
                        end
                    catch
                        continue;
                    end
                    new_system(mdl_name);
                    
                    hws = get_param(mdl_name, 'modelworkspace');
                    blkPath = fullfile(mdl_name, 'P');
                    
%                     if isfield(s, 'Table') && isnumeric(s.Table)
%                         T = s.Table;
%                         hws.assignin('T', T);
%                         s.Table = 'T';
%                     end
                    
                    TableDim = [];
                    if isfield(s, 'TableDim')
                        TableDim = s.TableDim;
                        s = rmfield(s, 'TableDim');
                    end
                    
                    if strcmp(s.TableSpecification, obj.TableSpecification{2})
                        % lookup table object
                        dt = 'auto';
                        if isfield(s, 'TableDataTypeStr') ...
                                && ~MatlabUtils.startsWith(s.TableDataTypeStr, 'Inherit:')
                            dt = s.TableDataTypeStr;
                        end
                        obj.addLookupTableObjectToBaseWs(mdl_name, s.Table, dt, TableDim)
                    end
                    
                    
                    
                    blkParams = Block_Test.struct2blockParams(s);
                    add_block(obj.blkLibPath, blkPath, blkParams{:});
                    Block_Test.connectBlockToInportsOutports(blkPath);
                    
                    % go over inports
                    inport_list = find_system(mdl_name, ...
                        'SearchDepth',1, 'BlockType','Inport');
                    nbInpots = length(inport_list);
                    if isfield(s, 'TableSource') && ...
                            strcmp(s.TableSource, obj.TableSource{2})
                        if ~isempty(TableDim)
                            set_param(inport_list{nbInpots}, 'PortDimensions', mat2str(TableDim));
                        end
                        nbInpots = nbInpots - 1;
                    end
                    if ~strcmp(s.NumSelectionDims, '0')
                        set_param(inport_list{nbInpots}, 'OutMin', '0');
                        for selIdx = 1:str2num(s.NumSelectionDims)
                            if ~isempty(TableDim)
                                set_param(inport_list{nbInpots}, 'OutMax', num2str(TableDim(end- selIdx + 1)));
                            end
                            nbInpots = nbInpots -1;
                        end
                    end
                    if nbInpots > 0
                        if strcmp(s.RequireIndexFractionAsBus, 'on')
                            % input is a bus
                            PreLookup_Test.addBusObjectToBaseWorkspace(mdl_name);
                            for inpIdx = 1:nbInpots
                                set_param(inport_list{inpIdx}, ...
                                    'OutDataTypeStr', 'Bus: kfBus', ...
                                    'BusOutputAsStruct', 'on', 'OutMin', '0');
                                if ~isempty(TableDim)
                                    set_param(inport_list{inpIdx}, 'OutMax', num2str(TableDim(inpIdx)));
                                end
                            end
                        else
                            % index and fraction are seperate
                            dimIdx =1;
                            for inpIdx = 1:2:nbInpots
                                set_param(inport_list{inpIdx}, 'OutMin', '0');
                                if ~isempty(TableDim)
                                    set_param(inport_list{inpIdx}, 'OutMax', num2str(TableDim(dimIdx)));
                                    dimIdx = dimIdx + 1;
                                end
                            end
                            for inpIdx = 2:2:nbInpots
                                set_param(inport_list{inpIdx},...
                                    'OutMin', '-0.5', 'OutMax', '1.5');
                            end
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
                
                %RequireIndexFractionAsBus
                idx = mod(i1, length(obj.RequireIndexFractionAsBus)) + 1;
                s.RequireIndexFractionAsBus = obj.RequireIndexFractionAsBus{idx};
                
                %ValidIndexMayReachLast
                idx = mod(i1, length(obj.ValidIndexMayReachLast)) + 1;
                s.ValidIndexMayReachLast = obj.ValidIndexMayReachLast{idx};
                
                
                %IntermediateResultsDataTypeStr
                idx = mod(i1, length(obj.IntermediateResultsDataTypeStr)) + 1;
                s.IntermediateResultsDataTypeStr = obj.IntermediateResultsDataTypeStr{idx};
                
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
            i11=0;
            for i1 = 1 : 4
                s = struct();
                s.NumberOfTableDimensions = num2str(i1);
                
                for i2 = 1 : length( obj.TableSpecification )
                    s.TableSpecification = obj.TableSpecification{i2};
                    
                    for i3 = 1 : length ( obj.InterpMethod )
                        s.InterpMethod = obj.InterpMethod{i3};
                        
                        for i4 = 1 : length ( obj.ExtrapMethod )
                            s.ExtrapMethod = obj.ExtrapMethod{i4};
                            
                            %NumSelectionDims
                            i11 = mod(i11 + 1, i1+1);
                            s.NumSelectionDims =  num2str(i11);
                            
                            if i2 == 1
                                % Explicit values
                                for i5 = 1 : length ( obj.TableSource )
                                    s2 = s;
                                    s2.TableSource = obj.TableSource{i5};
                                    if i5 == 1
                                        s3 = s2;
                                        if i1 == 1
                                            % try dim = [2, 1]
                                            T = MatlabUtils.construct_random_doubles(1, 0, 127, [3 1]);
                                            s3.Table = mat2str(T);
                                            s3.TableDim = 3;
                                            params{end+1} = s3;
                                        elseif i1 == 2
                                            d1 = 2;
                                            d2 = 5;
                                            T = MatlabUtils.construct_random_doubles(1, 0, 127, [d1, d2]);
                                            s3.Table = mat2str(T);
                                            s3.TableDim = [d1, d2];
                                            params{end+1} = s3;
                                        elseif i1 == 3
                                            s3.Table = 'reshape(repmat([4 5 6 7 8;16 19 20 21 22;10 18 23 24 25],1,2),[2,5,3])';
                                            s3.TableDim = [2,5,3];
                                            params{end+1} = s3;
                                        else
                                            s3.Table = 'reshape(repmat([4 5 6 7 8;16 19 20 21 22;10 18 23 24 25],2,2),[2,5,3,2])';
                                            s3.TableDim = [2,5,3,2];
                                            params{end+1} = s3;
                                        end
                                        
                                        
                                    else
                                        % Table is Input port
                                        s3 = s2;
                                        if i1 == 1
                                            % try dim = [2, 1]
                                            s3.TableDim = 3;
                                            params{end+1} = s3;
                                        elseif i1 == 2
                                            d1 = 2;
                                            d2 = 5;
                                            s3.TableDim = [d1, d2];
                                            params{end+1} = s3;
                                        elseif i1 == 3
                                            d1 = 2;
                                            d2 = 5;
                                            d3 = 3;
                                            s3.TableDim = [d1, d2, d3];
                                            params{end+1} = s3;
                                        else
                                            d1 = 2;
                                            d2 = 5;
                                            d3 = 3;
                                            d4 = 2;
                                            s3.TableDim = [d1, d2, d3, d4];
                                            params{end+1} = s3;
                                        end
                                    end
                                end
                            else
                                % Table object
                                s3 = s;
                                s3.LookupTableObject = obj.LookupTableObject;
                                if i1 == 1
                                    % try dim = [2, 1]
                                    T = MatlabUtils.construct_random_doubles(1, 0, 127, [3 1]);
                                    s3.Table = mat2str(T);
                                    s3.TableDim = 3;
                                elseif i1 == 2
                                    T = MatlabUtils.construct_random_doubles(1, 0, 127, [3, 2]);
                                    s3.Table = mat2str(T);
                                    s3.TableDim = [3, 2];
                                elseif i1 == 3
                                    s3.Table = 'reshape(repmat([4 5 6 7 8;16 19 20 21 22;10 18 23 24 25],1,2),[2,5,3])';
                                    s3.TableDim = [2,5,3];
                                    
                                else
                                    s3.Table = 'reshape(repmat([4 5 6 7 8;16 19 20 21 22;10 18 23 24 25],2,2),[2,5,3,2])';
                                    s3.TableDim = [2,5,3,2];
                                end
                                params{end+1} = s3;
                            end
                        end
                    end
                end
                
            end
            
        end
        
        function addLookupTableObjectToBaseWs(obj, mdl, T, dt, TableDim)
            code = get_param(mdl, 'PreLoadFcn');
            
            code = sprintf('%s\n LUTObj = Simulink.LookupTable;', code);
            code = sprintf('%s\n LUTObj.Table.Value = %s;', code, T);
            code = sprintf('%s\n LUTObj.Table.DataType = ''%s'';', code, dt);
            code = sprintf('%s\n LUTObj.StructTypeInfo.Name = ''myLUTStruct'';', code);
            code = sprintf('%s\n LUTObj.BreakpointsSpecification = ''Reference'';', code);
            
            for i=1:length(TableDim)
                code = sprintf('%s\n LUTObj.Breakpoints{%d} = ''myBpSet%d'';', code, i, i);
                code = sprintf('%s\nmyBpSet%d = Simulink.Breakpoint;', code, i);
                code = sprintf('%s\nmyBpSet%d.Breakpoints.Value = %s;', code, i, mat2str((1:TableDim(i))));
            end
            set_param(mdl, 'PreLoadFcn', code);
            % add it to base ws too to compile the model
            evalin('base', code);
        end
    end
end

