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
classdef BitwiseOperator_Test < Block_Test
    %BitwiseOperator_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'BitwiseOperator_TestGen';
        blkLibPath = 'simulink/Logic and Bit Operations/Bitwise Operator';
    end
    
    properties
        % properties that will participate in permutations
        inputDataType = {'int8','uint8','int16', 'uint16'};
        logicop = {'AND','OR','NAND','NOR','XOR','NOT'};
        UseBitMask = {'on','off'};
        BitMaskRealWorld = {'Real World Value','Stored Integer'};
        NumInputPorts = {'1','2','3', '4'};
        %BitMask = {'bin2dec('11011001')'};
    end
    
    properties
        % other properties
        
    end
    
    methods
        function params = getParams(obj)
            params = {};
            pTreatMask = 0;
            pUseBitMask = 0;
            pNumInputPorts = 0;
            pInputDims = 0;
            for pOperator = 1 : numel(obj.logicop)
                for pInputDataType = 1:numel(obj.inputDataType)
                    s = struct();
                    
                    pUseBitMask = mod(pUseBitMask, ...
                        length(obj.UseBitMask)) + 1;
                    
                    
                    s.logicop = obj.logicop{pOperator};
                    s.inputDataType = obj.inputDataType{pInputDataType};
                    
                    % BitMask
                    if ~strcmp(s.logicop, 'NOT')
                        s.UseBitMask = obj.UseBitMask{pUseBitMask};
                        if strcmp(obj.UseBitMask{pUseBitMask}, 'on')
                            pTreatMask = mod(pTreatMask, ...
                                length(obj.BitMaskRealWorld)) + 1;
                            s.BitMaskRealWorld = obj.BitMaskRealWorld{pTreatMask};
                        end
                    end
                    
                    % NumInputPorts
                    if strcmp(obj.UseBitMask{pUseBitMask}, 'off')
                        pNumInputPorts = mod(pNumInputPorts, ...
                            length(obj.NumInputPorts)) + 1;
                        if strcmp(s.logicop, 'NOT')
                            s.NumInputPorts = '1';
                        else
                            s.NumInputPorts = obj.NumInputPorts{pNumInputPorts};
                        end
                    end
                    
                    
                    pInputDims  = mod(pInputDims, 3) + 1;
                    if pInputDims == 1
                        s.inputDims = '1';
                    elseif pInputDims == 2
                        s.inputDims = '[1 3]';
                    elseif pInputDims == 3
                        s.inputDims = '[2 3]';
                    end
                    params{end+1} = s;
                end
                
                
            end
            
        end
        
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();
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
                    inputDims  = s.inputDims;
                    s = rmfield(s,'inputDims');
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
                    
                    % rotate over input data type
                    set_param(inport_list{1}, ...
                        'OutDataTypeStr',inpDataType);
                    
                    set_param(inport_list{1}, ...
                        'PortDimensions', inputDims);
                    
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
        
        
        
        
        
    end
end

