%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: 
%   Trinh, Khanh V <khanh.v.trinh@nasa.gov>
%
% Notices:
%
% Copyright © 2019 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  
% All Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING, 
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY 
% THAT THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS 
% RESULTING FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY 
% DISCLAIMS ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, 
% IF PRESENT IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
% 
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR LOSSES 
% ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED ON, OR 
% RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT SHALL 
% INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS CONTRACTORS 
% AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE EXTENT 
% PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER SHALL BE 
% THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef MatlabFunction_Test < Block_Test
    %Bias_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'MatlabFunction_TestGen';
        blkLibPath = 'simulink/User-Defined Functions/MATLAB Function';
    end
    
    properties
        supportedFun = {'all', 'any', 'ceil', 'circshift', 'cumsum', ...
            'cumtrapz', 'diag', 'diff', 'dot', 'eye', 'fliplr', 'flip', 'flipud', ...
            'floor', 'iscolumn', 'isrow', 'isvector', 'length', ...
            'linspace', 'logspace', 'magic', 'mtimes', 'ndims', 'norm', ...
            'pascal', 'permute', 'repmat', 'rot90', 'round', 'size', ...
            'sum', 'trace', 'transpose', 'trapz', 'wilkinson'};
        %supportedFun = {'any'};
    end
    
    
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            for f=1:length(obj.supportedFun)
                fun_name = sprintf('matlabFunction_%sTest', obj.supportedFun{f});
                fun_handle = str2func(fun_name);
                params = fun_handle();
                nb_tests = length(params);
                for i=1 : nb_tests
                    skipTests = [];
                    if ismember(i,skipTests)
                        continue;
                    end
                    try
                        param = params{i};
                        %% creat new model
                        mdl_name = sprintf('%s_%s%d', obj.fileNamePrefix, ...
                            obj.supportedFun{f}, i);
                        addCondExecSS = false;
                        new_output_dir = fullfile(outputDir, obj.supportedFun{f});
                        MatlabUtils.mkdir(new_output_dir);
                        [blkPath, mdl_path, skip] = Block_Test.create_new_model(...
                            mdl_name, new_output_dir, deleteIfExists, addCondExecSS);
                        if skip
                            continue;
                        end
                        
                        %% add the block
                        add_block(obj.blkLibPath, blkPath);
                        blockObj = find(slroot, '-isa', ...
                            'Stateflow.EMChart', 'Path', blkPath);
                        blockObj.Script = param.Script;
                        Block_Test.connectBlockToInportsOutports(blkPath);
                        
                        %% go over inports
                        try
                            blk_parent = get_param(blkPath, 'Parent');
                        catch
                            blk_parent = fileparts(blkPath);
                        end
                        inport_list = find_system(blk_parent, ...
                            'SearchDepth',1, 'BlockType','Inport');
                        
                        % rotate over input data type
                        for in=1:length(inport_list)
                            set_param(inport_list{in}, ...
                                'OutDataTypeStr',param.inDT{in});
                            
                            set_param(inport_list{in}, ...
                                'PortDimensions', param.inDim{in});
                        end
                        failed = Block_Test.setConfigAndSave(mdl_name, mdl_path);
                        if failed, display(param), end
                        
                        
                    catch me
                        display(param);
                        display_msg(['Model failed: ' mdl_name], ...
                            MsgType.DEBUG, 'generateTests', '');
                        display_msg(me.getReport(), MsgType.ERROR, 'generateTests', '');
                        bdclose(mdl_name)
                    end
                end
            end
        end
        
        
    end
end

