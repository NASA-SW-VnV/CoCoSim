function [  ] = Assertion_pp( model )
%ASSERTION_PROCESS disable all assertions to stop simulation when assertion
%fails
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assertion_list = find_system(model,'BlockType','Assertion');
if not(isempty(assertion_list))
    display_msg('Processing Assetions...', MsgType.INFO, 'assertion_process', '');
    for i=1:numel(assertion_list)
        ass = assertion_list{i};
        set_param(ass,'StopWhenAssertionFail', 'off')
    end
    display_msg('Done\n\n', MsgType.INFO, 'assertion_process', '');
end

end

