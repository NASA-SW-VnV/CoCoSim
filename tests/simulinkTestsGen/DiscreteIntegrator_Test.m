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
classdef DiscreteIntegrator_Test < Block_Test
    %DiscreteFirFilter_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'DiscreteIntegrator_TestGen';
        blkLibPath = 'simulink/Discrete/Discrete-Time Integrator';
    end
    
    properties
        % properties that will participate in permutations
        inDataTypeKeys = {...
            'Inherit: auto', ...
            'single',...
            'double',...
            'int8', ...
            'uint8',...
            'int16'};
        outDataTypeValues = {...
            {'Inherit: Inherit via internal rule', 'Inherit: Inherit via back propagation', 'double','single','int8','uint8', 'int16','uint16'}, ... %'Inherit: auto'
            {'single'},...        % 'single'
            {'double'},...        % 'double'
            {'int8', 'int16'},...        % 'int8'
            {'uint8', 'uint16'},...        % 'uint8'
            {'int16'}...        % 'int16'
            };
        in2OutDTMap ; % defined in the constructor
    end
    properties
        IntegratorMethod = {'Integration: Forward Euler',...
            'Integration: Backward Euler','Integration: Trapezoidal',...
            'Accumulation: Forward Euler',...
            'Accumulation: Backward Euler','Accumulation: Trapezoidal'};
        gainval = {'1.0','2.0'};
        ExternalReset = {'none', 'none', 'none', ... % increase none cases
            'rising','falling','either','level',...
            'sampled level'};
        
        
        OutDataTypeStr = {...
            'Inherit: Inherit via back propagation','double',...
            'single','int8','uint8','int16','uint16'};
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32','boolean'};   
        % other properties
        InitialConditionSource = {'internal','external'};
        InitialCondition = {'7'};   % scalar or vector
        InitialConditionSetting = {'State (most efficient)','Output'};
        SampleTime = {'0.1'};
        LimitOutput =  {'off','on'};
        UpperSaturationLimit = {'100'};
        LowerSaturationLimit = {'5'};
        ShowSaturationPort =  {'off','on'};
        ShowStatePort =  {'off','on', 'off'};
        IgnoreLimit =  {'off','on'};
        OutMin = {'0','.5','5'};
        OutMax = {'0.1','.51','6','8'};         
        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', ...
            'Round', 'Simplest', 'Zero'};
        LockScale = {'off','on'};     
        SaturateOnIntegerOverflow = {'off','on'};
        StateName = {''};
        StateMustResolveToSignalObject =  {'off','on'};
        StateSignalObject = {[]};
        StateStorageClass = {'Auto','Model default','ExportedGlobal',...
            'ImportedExtern','ImportedExternPointer','Custom'};
        RTWStateStorageTypeQualifier = {''};
        
        
    end
    methods
        % Constructor
        function obj = DiscreteIntegrator_Test()
            obj.in2OutDTMap  = containers.Map(obj.inDataTypeKeys, obj.outDataTypeValues);
        end
    end
    
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();             
            fstInDims = {'1', '1', '1', '2', '[2,3]'};          
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
                    set_param(inport_list{1}, ...
                        'OutDataTypeStr',inpDataType);
                    
                    dim_Idx = mod(i, length(fstInDims)) + 1;
                    set_param(inport_list{1}, ...
                        'PortDimensions', fstInDims{dim_Idx});

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
        
        function params = getParams(obj)
            params = {};  
            inpDataType = obj.in2OutDTMap.keys();
            for inTypeIdx = 1:length(inpDataType)
                outDataTypeStr = obj.in2OutDTMap(inpDataType{inTypeIdx});
                for outTypeIdx = 1:length(outDataTypeStr)
                    s = struct();
                    s.inputDataType = inpDataType{inTypeIdx};
                    s.OutDataTypeStr = outDataTypeStr{outTypeIdx};
                    
                    %IntegratorMethod
                    s.IntegratorMethod = obj.IntegratorMethod{...
                        mod(length(params), length(obj.IntegratorMethod)) + 1};
                    
                    %gainval
                    s.gainval = obj.gainval{...
                        mod(length(params), length(obj.gainval)) + 1};
                    
                    %ExternalReset
                    s.ExternalReset = obj.ExternalReset{...
                        mod(length(params), length(obj.ExternalReset)) + 1};
                    
                    %InitialConditionSource
                    s.InitialConditionSource = obj.InitialConditionSource{...
                        mod(length(params), length(obj.InitialConditionSource)) + 1};
                    %InitialCondition
                    s.InitialCondition = obj.InitialCondition{...
                        mod(length(params), length(obj.InitialCondition)) + 1};
                    %InitialConditionSetting
                    s.InitialConditionSetting = obj.InitialConditionSetting{...
                        mod(length(params), length(obj.InitialConditionSetting)) + 1};
                    
                    %LimitOutput
                    s.LimitOutput = obj.LimitOutput{...
                        mod(length(params), length(obj.LimitOutput)) + 1};
                    %UpperSaturationLimit
                    s.UpperSaturationLimit = obj.UpperSaturationLimit{...
                        mod(length(params), length(obj.UpperSaturationLimit)) + 1};
                    %LowerSaturationLimit
                    s.LowerSaturationLimit = obj.LowerSaturationLimit{...
                        mod(length(params), length(obj.LowerSaturationLimit)) + 1};
                    
                    %ShowSaturationPort
                    s.ShowSaturationPort = obj.ShowSaturationPort{...
                        mod(length(params), length(obj.ShowSaturationPort)) + 1};
                    %ShowStatePort
                    s.ShowStatePort = obj.ShowStatePort{...
                        mod(length(params), length(obj.ShowStatePort)) + 1};
                    
                    % RoundMeth
                    iRound = mod(length(params), ...
                        length(obj.RndMeth)) + 1;
                    s.RndMeth = obj.RndMeth{iRound};
                    %SaturateOnIntegerOverflow
                    s.SaturateOnIntegerOverflow = obj.SaturateOnIntegerOverflow{...
                        mod(length(params), length(obj.SaturateOnIntegerOverflow)) + 1};
                    
                    
                    params{end+1} = s;
                end
            end
        end

    end
end

