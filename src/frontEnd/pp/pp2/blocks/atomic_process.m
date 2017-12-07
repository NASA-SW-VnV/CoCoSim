function atomic_process( new_model_base )
%ATOMIC_PROCESS change all blocks to be atomic

% Configure any subsystem to be treated as Atomic
ssys_list = find_system(new_model_base,'BlockType','SubSystem');
if not(isempty(ssys_list))
    display_msg('Processing Subsystem blocks', MsgType.INFO, 'PP', '');
    for i=1:length(ssys_list)
        %disp(ssys_list{i})
        try
            set_param(ssys_list{i},'TreatAsAtomicUnit','on');
            set_param(ssys_list{i},'MinAlgLoopOccurrences','on');
        catch
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'PP', '');
end

solveAlgebraicLoops(new_model_base);
end

function solveAlgebraicLoops(new_model_base)
% set off atomic for subsystems that cause algebraic loops
% this function is rucursive, because after solving each block we should
% rerun the process in order to check if the solved block has broken the
% algebraic loop. That increase the number of atomic blocks instead of
% turning off all blocks detected in algebraic loop.
code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
try
    warning off;
    evalin('base',code_on);
catch ME
    causes = ME.cause;
    for c=causes'
        if strcmp(c{1}.identifier,  'Simulink:Engine:BlkInAlgLoopErr')
            display_msg('Algebraic Loop detected', MsgType.INFO, 'PP', '');
            msg = c{1}.message;
            tokens = regexp(msg, 'matlab:open\w+\s*\(''([^''])+''', 'tokens', 'once');
            subsys = tokens{1};
            try
                display_msg(['Turn off atomic in block' subsys], MsgType.INFO, 'PP', '');
                set_param(subsys,'TreatAsAtomicUnit','off');
                solveAlgebraicLoops(new_model_base);
            catch
            end
            break;
        end
    end
    return;
end
code_off=sprintf('%s([], [], [], ''term'')', new_model_base);
evalin('base',code_off);

end