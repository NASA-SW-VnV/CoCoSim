%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function hasMemory = instr_mayHaveMemory(instr)
hasMemory = false;
try
    switch instr.kind
        case {'arrow', 'pre', 'statefulcall'}
            hasMemory = true;
            
        case {'local_assign', 'reset', 'operator', 'statelesscall', 'functioncall'}
            hasMemory = false;
            
        case 'branch'
            branches = instr.branches;
            for b=fieldnames(branches)'
                branch_exprs = branches.(b{1}).instrs;
                for var = fieldnames(branch_exprs)'
                    hasMemory = Lus2SLXUtils.instr_mayHaveMemory(branch_exprs.(var{1}));
                    if hasMemory
                        break;
                    end
                end
                if hasMemory
                    break;
                end
            end
            
    end
catch ME
    display_msg('Error Launched while executing instr_mayHaveMemory', MsgType.DEBUG, 'LUS2SLX.instr_mayHaveMemory', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'LUS2SLX', '');
    hasMemory = true;
end

end
