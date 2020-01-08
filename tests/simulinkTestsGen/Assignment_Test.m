classdef Assignment_Test < Block_Test
    %Assignment_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Assignment_TestGen';
        blkLibPath = 'simulink/Math Operations/Assignment';
    end
    
    properties
        % properties that will participate in permutations
        NumberOfDimensions = {'1','2','3','4'}
        IndexOptionArray =  {'Assign all','Index vector (dialog)',...
            'Index vector (port)','Starting index (dialog)',...
            'Starting index (port)'};
    end
    
    properties
        % other properties
        IndexMode =  {'Zero-based','One-based'};     
        OutputInitialize = {'Initialize using input port <Y0>',...
            'Specify size for each dimension in table'};
        SampleTime = {'-1'};
        IndexParamArray = {};  % cell array defined in function getPermutations 
        OutputSizeArray = {};  % cell array defined in function getPermutations 
        DiagnosticForDimensions = {};  % not used
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();
            inputDataType = {'double', 'single', 'double', 'single',...
                'double', 'single', 'double', 'single',...
                'int8', 'uint8', 'int16', 'uint16'};              
            nb_tests = length(params);
            condExecSSPeriod = floor(nb_tests/length(Block_Test.condExecSS));
            if condExecSSPeriod <= 1
                condExecSSPeriod = 5;
            end
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
                    %hws = get_param(mdl_name, 'modelworkspace');
                                        
                     %% add the block
                    % 
                    dim_Y0 =  s.dim_Y0;
                    s = rmfield(s,'dim_Y0');
                    dim_U = s.dim_U;
                    s = rmfield(s,'dim_U');
                    dim_out = s.dim_out;
                    s = rmfield(s,'dim_out');
                    Y0_portNumber = s.Y0_portNumber;
                    s = rmfield(s,'Y0_portNumber');
                    IndexPortNumber = s.IndexPortNumber;
                    s = rmfield(s,'IndexPortNumber');                 
                    
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
                    
                    % rotate over input data type
                    inpType_Idx = mod(i, length(inputDataType)) + 1;
                    
                    % set Y0 dimension
                    set_param(inport_list{1}, ...
                        'PortDimensions', mat2str(dim_Y0),...
                        'OutDataTypeStr',inputDataType{inpType_Idx});
                    
                    % set U dimension
                    set_param(inport_list{2}, ...
                        'PortDimensions', mat2str(dim_U),...
                        'OutDataTypeStr',inputDataType{inpType_Idx});
                                      
                    portOffset = 1 + Y0_portNumber;
                    for portId=1:IndexPortNumber
                        outMin = '1';
                        outMax = '2';
                        if strcmp(s.IndexMode,'One-based')
%                             if strcmp(s.IndexOptionArray{,'Starting index (port)')
%                                 outMin = '1';
%                                 outMax = '2';
%                             end
                        else
                            set_param(inport_list{portId+portOffset},...
                                'OutMin', '0', 'OutMax', '2');   
                            outMin = '0';
                            outMax = '1';
%                             if strcmp(s.IndexOptionArray,'Starting index (port)')
%                                 outMin = '0';
%                                 outMax = '1';                                
%                             end                            
                        end
                        set_param(inport_list{portId+portOffset},...
                            'OutMin', outMin, 'OutMax', outMax);
                        % add Simulink/Discontinuities/Saturation block
                        saturationPath = fullfile(blk_parent, ...
                            sprintf('port_%d',portId));
                        add_block('simulink/Discontinuities/Saturation',...
                            saturationPath,'UpperLimit',outMax,...
                            'LowerLimit',outMin);
                        % remove existing connection
                        
                        assignmentBlockPortHandles = get_param(blkPath, ...
                            'PortHandles');
                        inportPortHandles = get_param(...
                            inport_list{portId+portOffset}, 'PortHandles');
                        
                        delete_line(blk_parent,...
                            inportPortHandles.Outport,...
                            assignmentBlockPortHandles.Inport(portId+portOffset));
                        % add new connection
                        % saturation block to assignment
                        satOutPortHandles = get_param(...
                            saturationPath, 'PortHandles');                        
                        add_line(blk_parent,...
                            satOutPortHandles.Outport, ...
                            assignmentBlockPortHandles.Inport(portId+portOffset),...
                            'autorouting', 'on');
                        % input to saturation
                        add_line(blk_parent,...
                            inportPortHandles.Outport,...
                            satOutPortHandles.Inport,...                            
                            'autorouting', 'on');                        
                    end
                    BlocksPosition_pp(mdl_name);
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
            for p1 = 1 : length(params1)
                s = params1{p1};
                
                params2{p1} = s;
            end
        end
        
        % Y0 shall have 3 elements for each dimension
        % U shall have 2 elements for each dimension if not required to be
        % 3 by 'Assign all'.
        function params = getPermutations(obj)
            params = {};
       
            for pDim = 1 : 4   % pDim: number of ouput dimensions

                s = struct();
                s.NumberOfDimensions = num2str(pDim);
                % odd number: Zero-based index, even: One-based index
                if mod(pDim,2) == 0
                    s.IndexMode = 'Zero-based';
                else
                    s.IndexMode = 'One-based';
                end
                s.IndexOptionArray = cell(pDim,1);
                s.IndexParamArray = cell(1,pDim);
                s.OutputSizeArray = cell(1,pDim);
                
               
                
                for pIndOpt = 1 : length( obj.IndexOptionArray )
                    s.dim_Y0 = 3*ones(1,pDim);
                    s.dim_U = 2*ones(1,pDim);
                    s.dim_out = s.dim_Y0;
                    index = pIndOpt;  % 1st dim will be pIndOpt
                    s.Indices = '';
                    s.Y0_portNumber = 1;
                    s.IndexPortNumber = 0;
                    
                    if numel(params) == 7
                        disp('break in getPermutations');
                    end
                    
                    for indOpt4dim = 1:pDim
                        s.IndexOptionArray(indOpt4dim) = obj.IndexOptionArray(index);
                        % assign required IndexParamArray or OutputSizeArray
                        if index == 1   % 'Assign all'
                            s.dim_U(indOpt4dim) = 3;
                            s.Indices = strcat(s.Indices,'[]');
                        elseif index == 2  % 'Index vector (dialog)'
                            s.IndexParamArray{indOpt4dim} = num2str([1,2]);
                            s.Indices = strcat(s.Indices,'[1,2]');
                        elseif index == 3 % 'Index vector (port)'
                            s.Indices = strcat(s.Indices,'[]');
                            s.IndexPortNumber = s.IndexPortNumber + 1;
                        elseif index == 4 % 'Starting index (dialog)'
                            s.IndexParamArray{indOpt4dim} = num2str(1);
                            s.Indices = strcat(s.Indices,'1');
                        else % 'Starting index (port)'
                            s.Indices = strcat(s.Indices,'[]');
                            s.IndexPortNumber = s.IndexPortNumber + 1;
                        end
                        
                        index = index + 1;  % after 1st dim, cycle through option list
                        if index > length( obj.IndexOptionArray )
                            index = 1;
                        end
                        if indOpt4dim<pDim
                            s.Indices = strcat(s.Indices,',');
                        end
                    end
                    % pIndOpt == 1 is Assign all
                    % pIndOpt == 3 is index vector (port)
                    % pIndOpt == 5 is starting index (port)
%                     if pIndOpt==2  % index vector (dialog)
%                         continue;
%                     elseif pIndOpt==4  % starting index (dialog)
%                         continue;
%                     end
                    
                    params{end+1} = s;
                    
                end
                
            end
        end

    end
end

