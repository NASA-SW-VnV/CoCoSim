function [status, errors_msg] = Assertion_pp( model )
%Assertion_pp disable all assertions to stop simulation when assertion
%fails
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
errors_msg = {};

assertion_list = find_system(model, ...
    'LookUnderMasks', 'all','BlockType','Assertion');
if not(isempty(assertion_list))
    display_msg('Processing Assetions...', MsgType.INFO, 'assertion_process', '');
    for i=1:numel(assertion_list)
        try
            ass = assertion_list{i};
            set_param(ass,'StopWhenAssertionFail', 'off')
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('Assertion pre-process has failed for block %s', assertion_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'assertion_process', '');
end

end

