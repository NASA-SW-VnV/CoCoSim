classdef PreLookup_Test < Block_Test
    %PreLookup_Test defines Prelookup block parameters and generate tests
    
    properties(Constant)
        fileNamePrefix = 'preLookupTestGen';
        blkLibPath = 'simulink/Lookup Tables/Prelookup';
    end
    properties
        BreakpointsSpecification = {'Explicit values', 'Even spacing', 'Breakpoint object'}; %Specification
        BreakpointObject = ''; % Name of breakpoint object
        BreakpointsFirstPoint = {'-300'}; % First point
        BreakpointsSpacing = {'30'}; % Spacing
        BreakpointsNumPoints = {'20'}; % Number of points
        BreakpointsData = {''}; %Value
        BreakpointsDataSource = {'Dialog', 'Input port'}; %Source
        IndexSearchMethod = {'Evenly spaced points', 'Linear search','Binary search'};
        BeginIndexSearchUsingPreviousIndexResult = {'off', 'on'};
        OutputSelection = {'Index and fraction', 'Index and fraction as bus', 'Index only'};
        ExtrapMethod = {'Clip', 'Linear'};
        UseLastBreakpoint = {'off', 'on'};
        DiagnosticForOutOfRangeInput = {'None', 'Warning', 'Error'};
        RemoveProtectionInput = {'off', 'on'};
        SampleTime = {'-1'};
        BreakpointDataTypeStr = {'Inherit: Same as input',...
            'Inherit: Inherit from ''Breakpoint data''',...
            'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32'};
        BreakpointMin = {'[]'};
        BreakpointMax = {'[]'};
        IndexDataTypeStr = {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32'};
        FractionDataTypeStr = {'double', 'single'};
        LockScale = {'off', 'on'};
        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', 'Round', 'Simplest', 'Zero'};
    end
    
    methods
        
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();
            fstInDims = {'1', '1', '1', '3', '[2,3]'};
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
                    if isfield(s, 'OutputBusDataTypeStr')
                        PreLookup_Test.addBusObjectToBaseWorkspace(mdl_name);
                    end
                    if strcmp(s.BreakpointsSpecification, obj.BreakpointsSpecification{3})
                        obj.addBreakpointObjectToBaseWs(mdl_name);
                    end
                    
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
                    if ~isempty(inport_list)
                        
                        if length(inport_list) >= 2
                            % replace Inport with constant for breakpoints inport
                            failed = PP2Utils.replace_one_block(inport_list{2},...
                                'simulink/Sources/Constant');
                            if ~failed
                                [V, bmin, bmax] = obj.getRandomValues();
                                set_param(inport_list{2}, 'Value', V);
                                s.BreakpointMin = num2str(min(bmin - 10, 0));
                                s.BreakpointMax = num2str(bmax + 10);
                            end
                        end
                        if length(inport_list) >= 1
                            % Set dimension for first inport
                            dim_Idx = mod(i, length(fstInDims)) + 1;
                            set_param(inport_list{1}, 'PortDimensions', ...
                                fstInDims{dim_Idx});
                            if isfield(s, 'BreakpointMin')
                                % to generate meaningful tests.
                                set_param(inport_list{1}, 'OutMin', s.BreakpointMin);
                                set_param(inport_list{1}, 'OutMax', s.BreakpointMax);
                            end
                        end
                    end
                    
                    %% set model configuration parameters and save model if it compiles
                    Block_Test.setConfigAndSave(mdl_name, mdl_path);
                catch me
                    display_msg(me.getReport(), MsgType.ERROR, 'generateTests', '');
                    bdclose(mdl_name)
                end
            end
        end
        function params2 = getParams(obj)
            
            params1 = [obj.getExplicitValuesParams(), ...
                obj.getEvenSpacingParams(), obj.getBreakpointObjectParams()];
%             params1 = obj.getBreakpointObjectParams();
            params2 = cell(1, length(params1));
            for i1 = 1 : length(params1)
                s = params1{i1};
                i2 = mod(i1, length(obj.OutputSelection)) + 1;
                s.OutputSelection = obj.OutputSelection{i2};
                
                
                
                i4 = mod(i1, length(obj.BreakpointDataTypeStr)) + 1;
                s.BreakpointDataTypeStr = obj.BreakpointDataTypeStr{i4};
                
                if i2 == 2
                    s.OutputBusDataTypeStr = 'Bus: kfBus';
                else
                    i5 = mod(i1, length(obj.IndexDataTypeStr)) + 1;
                    s.IndexDataTypeStr = obj.IndexDataTypeStr{i5};
                    
                    i6 = mod(i1, length(obj.FractionDataTypeStr)) + 1;
                    s.FractionDataTypeStr = obj.FractionDataTypeStr{i6};
                end
                i7 = mod(i1, length(obj.RndMeth)) + 1;
                s.RndMeth = obj.RndMeth{i7};
                
                i8 = mod(i1, length(obj.UseLastBreakpoint)) + 1;
                s.UseLastBreakpoint = obj.UseLastBreakpoint{i8};
                
                if (i2 == 3 || i4 > 4 )
                    % Linear extrapolation is not supported when outputselection is index only
                    
                    %'Extrapolation method' set to 'Linear' is supported
                    % only when the input, breakpoint and fraction output
                    % are all floating-point data types and the index data
                    % type specifies a built-in integer.
                    i3 = 1;
                else
                    
                    i3 = mod(i1, length(obj.ExtrapMethod)) + 1;
                end
                s.ExtrapMethod = obj.ExtrapMethod{i3};
                
                params2{i1} = s;
            end
        end
        %%
        function params = getExplicitValuesParams(obj)
            params = {};
            breakpointsSpecification = obj.BreakpointsSpecification{1};
            for i=1:length(obj.BreakpointsDataSource)
                s = struct();
                s.BreakpointsSpecification = breakpointsSpecification;
                s.BreakpointsDataSource = obj.BreakpointsDataSource{i};
                % generate 10 random test for each case
                for k = 1 : 3
                    if i==1
                        % Dialog
                        [s.BreakpointsData, bmin, bmax] = obj.getRandomValues();
                        s.BreakpointMin = num2str(bmin - 10);
                        s.BreakpointMax = num2str(bmax + 10);
                    end
                    for j=2:length(obj.IndexSearchMethod)
                        s2 = s;
                        s2.IndexSearchMethod = obj.IndexSearchMethod{j};
                        s2.BeginIndexSearchUsingPreviousIndexResult = 'off';
                        params{end+1} = s2;
                        s2.BeginIndexSearchUsingPreviousIndexResult = 'on';
                        params{end+1} = s2;
                    end
                end
            end
        end
        
        function params = getEvenSpacingParams(obj)
            params = {};
            for k = 1 : 10
                s = struct();
                s.BreakpointsSpecification = obj.BreakpointsSpecification{2};
                firstPoint = MatlabUtils.construct_random_integers(1, 0, 60, 'int8', 1);
                lastPoint = MatlabUtils.construct_random_integers(1, firstPoint+3, 127, 'int8',1);
                spacing = 3;% should be greater than 1
                s.BreakpointsFirstPoint = num2str(firstPoint);
                s.BreakpointsSpacing = num2str(spacing);
                s.BreakpointsNumPoints = num2str(floor((lastPoint - firstPoint)/spacing));
                s.IndexSearchMethod = obj.IndexSearchMethod{1};
                s.BreakpointMin = num2str(firstPoint - 10);
                s.BreakpointMax = num2str(lastPoint + 10);
                params{k} = s;
            end
        end
        
        function params = getBreakpointObjectParams(obj)
            params = {};
            for k = 1 : 3
                s = struct();
                s.BreakpointsSpecification = obj.BreakpointsSpecification{3};
                s.BreakpointObject = 'myBpSet';
                s.BreakpointMin = num2str(-5);
                s.BreakpointMax = num2str(5);
                params{k} = s;
            end
        end
        %%
        function [Vstr, firstPoint, lastPoint] = getRandomValues(obj)
            % Values must be strictly monotonically increasing after conversion to its run-time data type
            % we prefer using even spacing value to make sure casting of values to int
            % will not have the same value
            firstPoint = MatlabUtils.construct_random_doubles(1, 0, 50, 1);
            lastPoint = MatlabUtils.construct_random_doubles(1, firstPoint+3, 127, 1);
            if firstPoint > lastPoint
                tmp = firstPoint;
                firstPoint = lastPoint;
                lastPoint = tmp;
            end
            spacing = 1.5;% should be greater than 1
            V = (firstPoint:spacing:lastPoint);
            Vstr = mat2str(V);
            
        end
        
        
        
        function addBreakpointObjectToBaseWs(obj, mdl)
            code = 'myBpSet = Simulink.Breakpoint;';
            code = sprintf('%s\nmyBpSet.Breakpoints.Value = [-2 -1 0 1 2];', code);
            set_param(mdl, 'PreLoadFcn', code);
        end
    end
    
    methods(Static)
        function addBusObjectToBaseWorkspace(mdl)
            %             hws = get_param(mdl, 'modelworkspace');
            code = get_param(mdl, 'PreLoadFcn');
            code = sprintf('%s\nelems(1) = Simulink.BusElement;', code);
            code = sprintf('%s\nelems(1).Name = ''Index'';', code);
            code = sprintf('%s\nelems(1).DataType = ''int8'';', code);
            
            code = sprintf('%s\nelems(2) = Simulink.BusElement;', code);
            code = sprintf('%s\nelems(2).Name = ''Fraction'';', code);
            code = sprintf('%s\nelems(2).DataType = ''double'';', code);
            
            code = sprintf('%s\nkfBus = Simulink.Bus;', code);
            code = sprintf('%s\nkfBus.Elements = elems;', code);
            code = sprintf('%s\nclear elems;', code);
            code = sprintf('%s\nassignin(''base'', ''kfBus'', kfBus);', code);
            %             hws.assignin('kfBus', kfBus);
            set_param(mdl, 'PreLoadFcn', code);
        end
        
    end
end

