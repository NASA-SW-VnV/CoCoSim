function [  ] = assertion_process( model )
%ASSERTION_PROCESS disable all assertions to stop simulation when assertion
%fails


assertion_list = find_system(model,'BlockType','Assertion');
if not(isempty(assertion_list))
    display_msg('Processing Assetions...', Constants.INFO, 'assertion_process', '');
    for i=1:numel(assertion_list)
        ass = assertion_list{i};
        set_param(ass,'StopWhenAssertionFail', 'off')
    end
    display_msg('Done\n\n', Constants.INFO, 'assertion_process', '');
end

end

