function atomic_process( new_model_base )
%ATOMIC_PROCESS change all blocks to be atomic

% Configure any subsystem to be treated as Atomic
ssys_list = find_system(new_model_base,'BlockType','SubSystem');
if not(isempty(ssys_list))
    display_msg('Processing Subsystem blocks', Constants.INFO, 'PP', '');
    for i=1:length(ssys_list)
        %disp(ssys_list{i})
        try
            set_param(ssys_list{i},'TreatAsAtomicUnit','on');
        catch
        end
    end
    display_msg('Done\n\n', Constants.INFO, 'PP', '');
end


end

