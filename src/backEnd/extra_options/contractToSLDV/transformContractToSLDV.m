%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright � 2020 United States Government as represented by the 
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
%function new_model_path = transformContractToSLDV(model_path)
    %TRANSFORMCONTRACTTOSLDV transform COCOSPEC contract to SLDV Library:
    %Assertion, Proof, A...  
    
    [model_dir, model_name, ext] = fileparts(model_path);
    if ~bdIsLoaded(model_name), load_system(model_path); end
    new_model_path = fullfile(model_dir, strcat(model_name, '_SLDV', ext));
    save_system(model_name, new_model_path);
    if ~license('test', 'Simulink_Design_Verifier')
        errordlg('Simulink Design Verifier is needed.')
    end
    [~, model, ~] = fileparts(new_model_path);
    % remove all model reference
    try
        ModelReference_pp(model);
    catch
    end
    contractBlocks_list = find_system(model, ...
        'LookUnderMasks', 'all',  'MaskType', 'ContractBlock');
    if isempty(contractBlocks_list)
        msgbox(sprintf('Model %s contains no CoCoCpec Contracts.', model));
        return;
    end
    for i=1:numel(contractBlocks_list)
        block = contractBlocks_list{i};
        status = transformContract(block);
        if status
            msgbox(sprintf('Failed processing Contract %s.', block));
        end
    end
    open(new_model_path);
end


function status = transformContract(block)
    status = 0;
    validator_blk = find_system(block, 'LookUnderMasks', 'all', ...
        'SearchDepth', 1, 'MaskType', 'ContractValidatorBlock');
    if isempty(validator_blk)
        msgbox(sprintf('Contract %s contains no validator block.', block));
        status = 0;
        return;
    elseif numel(validator_blk) > 1
        msgbox(...
            sprintf('Contract %s contains more than one validator block.',...
            block));
        status = 1;
        return;
    else
        validator_blk = validator_blk{1};
    end
    assumePorts = str2double(get_param(validator_blk, 'assumePorts'));
    guaranteePorts = str2double(get_param(validator_blk, 'guaranteePorts'));
    modePorts = str2double(get_param(validator_blk, 'modePorts'));
    ValidatorPortHandles = get_param(validator_blk, 'PortHandles');
    nbInputs = numel(ValidatorPortHandles.Inport);
    if assumePorts + guaranteePorts + modePorts ~= nbInputs
        msgbox(...
            sprintf(['Validator Block in Contract %s Mask Parameters '...
            'does not match number of its inputs.'], block));
        status = 1;
        return;
    end
    for i=1:nbInputs
        if i <= assumePorts
            sldvBlkPath = 'sldvlib/Objectives and Constraints/Assumption';
        else
            sldvBlkPath = 'sldvlib/Objectives and Constraints/Proof Objective';
        end
        line = get_param(ValidatorPortHandles.Inport(i), 'line');
        if line == -1
            continue;
        end
        p = get_param(line, 'SrcPortHandle');
        try
            %remove Assume, Guarantee mask
            %delete mask
            srcBlk = get_param(line, 'SrcBlockHandle');
            p2 = Simulink.Mask.get(srcBlk);
            p2.delete
        catch
        end
        pos = get_param(p, 'Position');
        x = pos(1); y = pos(2);
        assertion_path = fullfile(block, strcat('Assertion', num2str(i)));
        assertionHandle = add_block(sldvBlkPath,...
            assertion_path,...
            'Position',[(x+100) y (x+150) (y+50)]);
        set_param(assertionHandle, 'outEnabled', 'off');
        DstBlkH = get_param(assertionHandle,'PortHandles');
        delete_line(line);
        add_line(block, p,DstBlkH.Inport(1), 'autorouting', 'on');
    end
    
    line = get_param(ValidatorPortHandles.Outport(1), 'line');
    if line > 0, delete_line(line); end
    outport_blk = find_system(block, 'LookUnderMasks', 'all', ...
        'SearchDepth', 1, 'BlockType', 'Outport');
    delete_block(validator_blk);
    delete_block(outport_blk);
    
    %delete mask
    p = Simulink.Mask.get(block);
    p.delete
    %create new mask
    set_param(block, 'TreatAsAtomicUnit', 'on');
    p = Simulink.Mask.create(block);
    p.set('Type', 'VerificationSubsystem',...
        'Display', ...
        'image(imread(''sldvicon_versubsys.png'',''BackGroundColor'',[1 1 1]),''center'');');
    
    
    % remove Guarantee, Assume and Mode MaskType
    guarantees = find_system(block, 'LookUnderMasks', 'all', ...
        'SearchDepth', 1, 'MaskType', 'ContractGuaranteeBlock');
    for i=1:numel(guarantees)
        set_param(guarantees{i}, 'MaskType', '');
    end
    assumes = find_system(block, 'LookUnderMasks', 'all', ...
        'SearchDepth', 1, 'MaskType', 'ContractAssumeBlock');
    for i=1:numel(assumes)
        set_param(assumes{i}, 'MaskType', '');
    end
    modes = find_system(block, 'LookUnderMasks', 'all', ...
        'SearchDepth', 1, 'MaskType', 'ContractModeBlock');
    for i=1:numel(modes)
        set_param(modes{i}, 'MaskType', '');
    end
end
