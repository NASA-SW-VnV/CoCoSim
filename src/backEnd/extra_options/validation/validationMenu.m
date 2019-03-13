function schema = validationMenu(callbackInfo)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    schema = sl_container_schema;
    schema.label = 'Validate compiler';
    schema.statustip = 'Validate the translation using one of the validations process';
    schema.autoDisableWhen = 'Busy';

    [validation_root, ~, ~] = fileparts(mfilename('fullpath'));
    validation_items{1} = fullfile(validation_root, 'lustreValidate', 'lusValidateMenu.m');
    schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, validation_items,...
                        'UniformOutput', false);

end
