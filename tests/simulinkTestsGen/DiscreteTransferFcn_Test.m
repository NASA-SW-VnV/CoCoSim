%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Author: 
%   Trinh, Khanh V <khanh.v.trinh@nasa.gov>
%
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef DiscreteTransferFcn_Test < Block_Test
    %DiscreteTransferFcn_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'DiscreteTransferFcn_TestGen';
        blkLibPath = 'simulink/Discrete/Discrete Transfer Fcn';
    end
    
    properties
        % properties that will participate in permutations
        Numerator = {'[1]','[0.5 0.7]'};
        Denominator = {'[1 0.5 2]','[1 0.5 2 1.5]'};
        InitialStates = {'0','1'};
        OutDataTypeStr = {'Inherit: Inherit via internal rule',...
            'int8','int16','int32'};
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32','boolean'};   
    end
    
    properties
        % other properties
        SampleTime = {'1'};
        a0EqualsOne = {'off','on'};
        NumCoefMin = {'[]'};
        NumCoefMax = {'[]'};
        DenCoefMin = {'[]'};
        DenCoefMax = {'[]'};
        OutMin = {'0','0.5','5'};
        OutMax = {'0.1','0.51','6','8'};                 
        StateDataTypeStr = {'Inherit: Same as input','int8','int16',...
            'int32'};
        NumCoefDataTypeStr = {'Inherit: Inherit via internal rule',...
            'int8','int16','int32'};
        DenCoefDataTypeStr = {'Inherit: Inherit via internal rule',...
            'int8','int16','int32'};
        NumProductDataTypeStr = {'Inherit: Inherit via internal rule',...
            'Inherit: Same as input','int8','int16','int32'};
        DenProductDataTypeStr = {'Inherit: Inherit via internal rule',...
            'Inherit: Same as input','int8','int16','int32'};
        NumAccumDataTypeStr = {'Inherit: Inherit via internal rule',...
            'Inherit: Same as input','Inherit: Same as product output',...
            'int8','int16','int32'};
        DenAccumDataTypeStr = {'Inherit: Inherit via internal rule',...
            'Inherit: Same as input','Inherit: Same as product output',...
            'int8','int16','int32'};
        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', ...
            'Round', 'Simplest', 'Zero'};
        LockScale = {'off','on'};  
        SaturateOnIntegerOverflow = {'off','on'};
        StateName = {''};
        StateMustResolveToSignalObject = {'off','on'};
        StateSignalObject = {};
        StateStorageClass = {'Auto','Model default','ExportedGlobal',...
            'ImportedExtern','ImportedExternPointer','Custom'};
        RTWStateStorageTypeQualifier = {''};
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();             
            fstInDims = {'1', '1', '1', '1', '1', '3'};          
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
                    inpDataType = s.inputDataType;
                    s = rmfield(s,'inputDataType');
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
                    
                    % rotate over input data type for U
%                     set_param(inport_list{1}, ...
%                         'OutDataTypeStr',inpDataType);
%                     
%                     dim_Idx = mod(i, length(fstInDims)) + 1;
%                     set_param(inport_list{1}, ...
%                         'PortDimensions', fstInDims{dim_Idx});

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
        
        function params = getPermutations(obj)
            params = {};       
            for pNumerator = 1 : numel(obj.Numerator)
                for pDenominator = 1 : numel(obj.Denominator)
                    rotateInputType = mod(length(params), ...
                        length(obj.inputDataType)) + 1;
                    iRound = mod(length(params), ...
                        length(obj.RndMeth)) + 1;
                    rotate2 = mod(length(params), 2) + 1;
                    s = struct();
                    s.Denominator = obj.Denominator{pDenominator};
                    s.Numerator = obj.Numerator{pNumerator};
                    s.inputDataType = obj.inputDataType(rotateInputType);
                    s.RndMeth = obj.RndMeth{iRound};
                    s.LockScale = obj.LockScale{rotate2};
                    params{end+1} = s;
                end
            end
        end

    end
end

