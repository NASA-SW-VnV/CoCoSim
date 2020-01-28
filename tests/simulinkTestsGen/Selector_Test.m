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
classdef Selector_Test < Block_Test
    %Selector_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Selector_TestGen';
        blkLibPath = 'simulink/Signal Routing/Selector';
    end
    
    properties
        % properties that will participate in permutations
        NumberOfDimensions = {'1','2','3','4'}
        IndexOptionArray =  {...
            'Select all',...
            'Index vector (dialog)',...
            'Index vector (port)',...
            'Starting index (dialog)',...
            'Starting index (port)'};
            % 'Starting and ending indices (port)' not supported
    end
    
    properties
        % other properties
        IndexMode =  {'Zero-based','One-based'};        
        SampleTime = {'-1'};
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
                'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32'};              
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
                    %hws = get_param(mdl_name, 'modelworkspace');
                                        
                     %% add the block
                    % 
                    dim_U = s.dim_U;
                    s = rmfield(s,'dim_U');
                    dim_out = s.dim_out;
                    s = rmfield(s,'dim_out');
                    IndexPortNumber = s.IndexPortNumber;
                    s = rmfield(s,'IndexPortNumber');   
                    ConstantParams = s.ConstantParams;
                    s = rmfield(s,'ConstantParams');  
                    
                    Block_Test.add_and_connect_block(obj.blkLibPath, blkPath, s);
                    
                    %% go over inports
                    try
                        blk_parent = get_param(blkPath, 'Parent');
                    catch
                        blk_parent = fileparts(blkPath);
                    end
                    inport_list = find_system(blk_parent, ...
                        'SearchDepth',1, 'BlockType','Inport');    
                    
                        % rotate over input data type
                    inpType_Idx = mod(i, length(inputDataType)) + 1;
                
                    
                    % set U dimension
                    if numel(dim_U) > 1
                        set_param(inport_list{1}, ...
                            'PortDimensions', mat2str(dim_U),...
                            'OutDataTypeStr',inputDataType{inpType_Idx});
                    end
                
                    portOffset = 1 ;
                    for portId=1:IndexPortNumber
                        constParams = {};
                        constParams{end+1} = 'Value';
                        constParams{end+1} = ConstantParams{portId};
                        in_name = get_param(inport_list{portId+portOffset},...
                            'Name');
                        constBlock = replace_block(blk_parent,'Name',...
                            in_name,...
                            'simulink/Sources/Constant','noprompt');
                        const_handle = find_system(blk_parent, ...
                        'SearchDepth',1, 'Name',in_name);
                        set_param(const_handle{1},constParams{:});
%                         const_name = fullfile(blk_parent, 'Const1');
%                         const_handle = add_block('simulink/Sources/Constant',...
%                             const_name,...
%                             'MakeNameUnique', 'on');
                        
%                         if strcmp(s.IndexMode,'One-based')
%                             set_param(inport_list{portId+portOffset}, 'OutMin', '1');
%                             set_param(inport_list{portId+portOffset}, 'OutMax', '3');
%                         else
%                             set_param(inport_list{portId+portOffset}, 'OutMin', '0');
%                             set_param(inport_list{portId+portOffset}, 'OutMax', '2');                            
%                         end
                    end                    
                    
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
        
        % U shall have 2 elements for each dimension if not required to be
        % 3 by 'Selector all'.
        function params = getPermutations(obj)
            params = {};
       
            for pDim = 1 : length( obj.NumberOfDimensions ) % pDim: number of ouput dimensions

                for pIndOpt = 1 : length( obj.IndexOptionArray )

                    s = struct();
                    s.NumberOfDimensions = num2str(pDim);
                    % odd number: Zero-based index, even: One-based index
                    if mode(numel(params),2) == 0
                        s.IndexMode = 'Zero-based';
                    else
                        s.IndexMode = 'One-based';
                        %s.IndexMode = 'Zero-based';
                    end
                    s.IndexOptionArray = cell(pDim,1);
                    s.IndexParamArray = cell(1,pDim);
                    s.OutputSizeArray = cell(1,pDim);      
                    if pDim == 1
                        s.InputPortWidth = '3';
                    end
                    s.dim_U = 2*ones(1,pDim);
                    s.dim_out = s.dim_U;
                    index = pIndOpt;  % 1st dim will be pIndOpt
                    s.Indices = '';
                    s.IndexPortNumber = 0;
                    s.ConstantParams = {};

                    for indOpt4dim = 1:pDim
                        s.IndexOptionArray{indOpt4dim} = obj.IndexOptionArray{index};
                        % assign required IndexParamArray or OutputSizeArray
                        if index == 1   % 'Selector all'
                            s.dim_U(indOpt4dim) = 3;
                            s.Indices = strcat(s.Indices,'[]');
                        elseif index == 2  % 'Index vector (dialog)'
                            s.IndexParamArray{indOpt4dim} = '[1,2]';
                            s.Indices = strcat(s.Indices,'[1,2]');
                        elseif index == 3 % 'Index vector (port)'
                            s.Indices = strcat(s.Indices,'[]');
                            s.IndexPortNumber = s.IndexPortNumber + 1;
                            s.ConstantParams{end+1} = '[1,2]';
                        elseif index == 4 % 'Starting index (dialog)'
                            s.IndexParamArray{indOpt4dim} = num2str(1);
                            s.Indices = strcat(s.Indices,'1');
                            s.OutputSizeArray{indOpt4dim} = num2str(2);
                        else % 'Starting index (port)'
                            s.Indices = strcat(s.Indices,'[]');
                            s.IndexPortNumber = s.IndexPortNumber + 1;
                            s.ConstantParams{end+1} = '1';
                            s.OutputSizeArray{indOpt4dim} ='2';
%                         else % 'Starting and ending indices (port)'
%                             s.Indices = strcat(s.Indices,'[]');
%                             s.IndexPortNumber = s.IndexPortNumber + 1;
%                             s.ConstantParams{end+1} = '[1,2]';
                        end
                        
                        index = index + 1;  % after 1st dim, cycle through option list
                        if index > length( obj.IndexOptionArray )
                            index = 1;
                        end
                        if indOpt4dim<pDim
                            s.Indices = strcat(s.Indices,',');
                        end
                        
                    end
                    % pIndOpt == 1 is Selector all
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

