%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: 
%   Trinh, Khanh V <khanh.v.trinh@nasa.gov>
%
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();
            fstInDims = {'1', '1', '1', '1', '1', '3', '[2,3]'};
            inputDataType = {'double', 'single', 'double', 'single',...
                'double', 'single', 'double', 'single',...
                'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32'};
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
                    
                    %% remove parametres that does not belong to block params
                    hws = get_param(mdl_name, 'modelworkspace');
                    
                    if isfield(s, 'LUTObj')
                        LUTObjName = sprintf('LUTObjLKnD%d', i);
                        s.LookupTableObject = LUTObjName;
                        hws.assignin(LUTObjName, s.LUTObj);
                        s = rmfield(s, 'LUTObj');
                    end
                    tableDim = 1;
                    if isfield(s, 'TableDim')
                        tableDim = s.TableDim;
                        s = rmfield(s, 'TableDim');
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
                    nbInpots = length(inport_list);

                    % if 'Nearest' then inputs must match break point data type
                    % if 'Even Spacing' then value of breakpoints spacing 
                    %    must fit in datatype to the last precision bit.
                    inpType_Idx = mod(i, length(inputDataType)) + 1;                    
                    if strcmp(s.UseOneInputPortForAllInputData, 'on')
                        set_param(inport_list{1}, 'PortDimensions', ...
                            num2str(length(tableDim)));

                        if ~strcmp(s.InterpMethod, 'Nearest')
                            if ~strcmp(s.BreakpointsSpecification, ...
                                    'Even spacing')
                                set_param(inport_list{1}, 'OutDataTypeStr', ...
                                    inputDataType{inpType_Idx});
                            end
                        end
                    else
                        for inpIdx = 1:nbInpots
                            set_param(inport_list{inpIdx},...
                                'OutMin', '0', 'OutMax', '127');
                            if ~strcmp(s.InterpMethod, 'Nearest')
                                if ~strcmp(s.BreakpointsSpecification, ...
                                        'Even spacing')
                                    set_param(inport_list{inpIdx}, 'OutDataTypeStr', ...
                                        inputDataType{inpType_Idx});
                                end
                            end
                        end
                        % test if the block behaves as scalar function.
                        dim_Idx = mod(i, length(fstInDims)) + 1;
                        set_param(inport_list{1}, 'PortDimensions', ...
                            fstInDims{dim_Idx});
                        
                        
                    end
                    
                    
                    
                    
                    %% set model configuration parameters and save model if it compiles
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
                if strcmp(s.InterpMethod, 'Nearest')
                    s.OutDataTypeStr = 'double';
                else
                    idx = mod(i1, length(obj.OutDataTypeStr)) + 1;
                    s.OutDataTypeStr = obj.OutDataTypeStr{idx};
                end
                
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
                            
                            
                            if strcmp(s.InterpMethod, 'Nearest')
                                tableDataTypeStr = 'double';
                                breakpointsForDimension1DataTypeStr = obj.BreakpointsForDimension1DataTypeStr{1};
                                
                            else
                                idx = mod(i1, length(obj.TableDataTypeStr)) + 1;
                                tableDataTypeStr = obj.TableDataTypeStr{idx};
                                
                                idx = mod(i1, length(obj.BreakpointsForDimension1DataTypeStr)) + 1;
                                breakpointsForDimension1DataTypeStr = obj.BreakpointsForDimension1DataTypeStr{idx};
                            end
                        end
                        
                        if i5 == 1
                            %'Explicit values'
                            if i2 < 3
                                % Table and breakpoints
                                s3.Table = table;
                                
                                s3.TableDataTypeStr = tableDataTypeStr;
                                
                                for d =1:length(dim)
                                    B = sort(MatlabUtils.construct_random_doubles(1, 0, 100, [dim(d) 1]));
                                    % to make it strictly monotonically increasing after conversion to its run-time data type
                                    B = B + (1:dim(d))';
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
                                    elseif strcmp(s.InterpMethod, 'Nearest')
                                        LUTObj.Breakpoints(d).DataType = 'double';
                                    end
                                end
                                s3.LUTObj = LUTObj;
                            end
                        else
                            %'Even spacing'
                            if i2 < 3
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
                                    elseif strcmp(s.InterpMethod, 'Nearest')
                                        LUTObj.Breakpoints(d).DataType = 'double';
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

    end
end

