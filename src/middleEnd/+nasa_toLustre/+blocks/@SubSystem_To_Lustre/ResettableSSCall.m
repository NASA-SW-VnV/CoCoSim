function [codes, ResetCondVar] = ResettableSSCall(parent, blk, ...
        node_name, blk_name, ...
        ResetType, codes, inputs, outputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    ResetCondName = sprintf('ResetCond_of_%s', blk_name);
    ResetCondVar = LustreVar(ResetCondName, 'bool');
    resetportDataType = blk.CompiledPortDataTypes.Reset{1};
    [lusResetportDataType, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(resetportDataType);
    resetInputs =nasa_toLustre.utils.SLX2LusUtils.getSubsystemResetInputsNames(parent, blk);
    cond = cell(1, blk.CompiledPortWidths.Reset);
    for i=1:blk.CompiledPortWidths.Reset
        [resetCode, status] =nasa_toLustre.utils.SLX2LusUtils.getResetCode(...
            ResetType, lusResetportDataType, resetInputs{i} , zero);
        if status
            display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                ResetType, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                MsgType.ERROR, 'Constant_To_Lustre', '');
            return;
        end
        cond{i} = resetCode;
    end
    ResetCond = BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, cond);
    %codes{end + 1} = sprintf('%s = %s;\n\t'...
    %    ,ResetCondName,  ResetCond);
    codes{end + 1} = LustreEq(VarIdExpr(ResetCondName), ResetCond);
    codes{end + 1} = ...
        LustreEq(outputs, ...
        EveryExpr(node_name, inputs, VarIdExpr(ResetCondName)));
end
