function [lus_action, outputs, inputs, external_libraries] = ...
        getPseudoLusAction(expreession, data_map, isCondition, action_parentPath, ignoreOutInputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
    
    if nargin < 3
        isCondition = false;
    end
    if nargin < 5
        ignoreOutInputs = false;
    end
    outputs = {};
    inputs = {};
    
    obj = nasa_toLustre.blocks.DummyBlock_To_Lustre();
    blk.Origin_path = action_parentPath;
    [lus_action, status] = ...
        nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.translate(obj, expreession, [], blk, ...
        data_map, [], '', false, true, false);
    if status
        ME = MException('COCOSIM:STATEFLOW', ...
            'ParseError: unsupported Action %s in StateFlow.', expreession);
        throw(ME);
    end
    external_libraries = obj.getExternalLibraries();
    
    if isempty(lus_action)
        return;
    end
    %ignoreOutInputs flag is used by unitTests.
    if ignoreOutInputs
        return;
    end
    [outputs, inputs] = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getInOutputsFromAction(lus_action, isCondition, data_map, expreession);
end

