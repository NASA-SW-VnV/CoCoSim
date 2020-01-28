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
classdef Sigbuilderblock_Test < Block_Test
    %SIGBUILDERBLOCK_TEST generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'sibBuilderBlock_TestGen';
        blkLibPath = 'simulink/Sources';
    end
    
    properties
        % properties that will participate in permutations
        SignalType = {'X_constant','X_step','X_pulse','X_square',...
            'X_sawtooth','X_sampled_Gaussian_noise',...
            'X_Pseudorandom_noise','X_Poisson_random_noise'};
        SignalValueAfterFinalTime = {'Extrapolate','Set to zero',...
            'Hold final value'};% We do not support,'Cyclic repetition'};
        SignalOutput = {'Ports', 'Bus'};
    end
    
    properties
        % other properties
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
%                     
%                     if isfield(s, 'M')
%                         M = s.M;
%                         s = rmfield(s, 'M');
%                     end
%                     
%                     if ~strcmp(s.OutDataTypeStr,'Inherit: auto')
%                         if strcmp(s.OutDataTypeStr, 'boolean')
%                             dt = 'logical';
%                         else
%                             dt = s.OutDataTypeStr;
%                         end
%                         if isa(M, 'timeseries')
%                             M.Data = cast(M.Data, dt);
%                         elseif isa(M, 'struct')
%                             M.signals.values = cast(M.signals.values, dt);
%                         end
%                     end
%                     
%                     hws.assignin(s.SignalType, M);
                    
                    %% add the block
                    %Block_Test.add_and_connect_block(obj.blkLibPath, blkPath, s);
                    blkParams = Block_Test.struct2blockParams(s);
                    %add_block(blkLibPath, blkPath, blkParams{:});
                    
                    time = 0.2 * [0:49]';
                    data = sin(time);
                    signames = 's1';
                    groupnames = 'group1';
%                     y = cos(t);
%                     z = 10*cos(t); 
%                    blkParams.OutputAfterFinalValue = blk.Content.FromWs.OutputAfterFinalValue;
                    
                    blk = signalbuilder(blkPath, 'create', time, data, signames, groupnames);
%                     blkParams.OutputAfterFinalValue = blk.Content.FromWs.OutputAfterFinalValue;
%                     blkParams.blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
                    
                    Block_Test.connectBlockToInportsOutports(blkPath);                    
                    
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
                idx = mod(i1, length(obj.ZeroCross)) + 1;
                s.ZeroCross = obj.ZeroCross{idx};                
                s.SampleTime = '-1';                
                params2{i1} = s;
            end
        end
        function params = getPermutations(obj)
            params = {};
            t = 0.2 * [0:49]';
%             x = sin(t);
%             y = cos(t);
%             z = 10*cos(t);
%             dim_idx = 1;
            for i1=1:length(obj.SignalType)
                s = struct();
                s.SignalType = obj.SignalType{i1};
                
                for i2=1:length(obj.SignalValueAfterFinalTime)
                    s.SignalValueAfterFinalTime = obj.SignalValueAfterFinalTime{i2};
                    
                    for i3=1:length(obj.SignalOutput)
%                         if i2==1 && i3==1  % if SignalValueAfterFinalTime is 'off',
%                             s.SignalOutput = ...
%                                 obj.SignalOutput{i2+1};
%                         else
%                             s.SignalOutput = obj.SignalOutput{i3};
%                         end
%                         
%                         if i1 == 1
%                             Matrix
%                             if dim_idx == 1
%                                 one dimension
%                                 s.M = [t, x];
%                             elseif dim_idx == 2
%                                 two dimensions
%                                 s.M = [t, x, y];
%                             elseif dim_idx == 3
%                                 3 dimensions
%                                 s.M = [t, x, y, z];
%                             end
%                         elseif i1 == 2
%                             timeseries
%                             if dim_idx == 1
%                                 one dimension
%                                 s.M = timeseries(rand(1,length(t)), t);
%                             elseif dim_idx == 2
%                                 two dimensions
%                                 s.M = timeseries(rand(2, 3,length(t)), t);
%                             elseif dim_idx == 3
%                                 3 dimensions
%                                 s.M = timeseries(rand(2, 3, 4,length(t)), t);
%                                 
%                             end
%                         else
%                             struct
%                             one dimension
%                             if dim_idx == 1
%                                 wave.time = t;
%                                 wave.signals.values = x;
%                                 wave.signals.dimensions =1;
%                                 s.M = wave;
%                             elseif dim_idx == 2
%                                 two dimensions
%                                 wave.time = t;
%                                 wave.signals.values = [x, y];
%                                 wave.signals.dimensions =2;
%                                 s.M = wave;
%                             elseif dim_idx == 3
%                                 3 dimensions
%                                 wave.time = t;
%                                 wave.signals.values = [x, y, z];
%                                 wave.signals.dimensions = 3;
%                                 s.M = wave;
%                             end
%                         end
                        params{end+1} = s;
%                         dim_idx = dim_idx + 1;
%                         if dim_idx > 3
%                             dim_idx = 1;
%                         end
                     end
                end
            end
        end
    end
end

