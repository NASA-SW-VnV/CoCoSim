%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [tree, status, unsupportedExp] = parse(exp)
    exp = regexprep(exp, '\s*', '');
    try
        [tree, status, unsupportedExp] = nasa_toLustre.utils.Fcn_Exp_Parser.parseE(exp);
    catch me
        if strcmp(me.identifier, 'COCOSIM:Fcn_Exp_Parser')
            display_msg(me.message, MsgType.ERROR, 'Fcn_Exp_Parser', '');
        end
        tree = {};
        status = 1;
        unsupportedExp = exp;
    end
end
