function set_mask_parameters(observer_path)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    mask = Simulink.Mask.create(observer_path);
    mask.Display = sprintf('%s', ImportLusUtils.get_observer_display());
    mask.IconUnits = 'normalized';
    mask.Type = 'Observer';
    mask.Description = ImportLusUtils.get_obs_description();
    mask.addParameter('Type', 'popup', 'Prompt', 'Type of annotation (pre/post...)', 'Name', 'AnnotationType', 'TypeOptions', {'ensures','requires','assert','observer'}, 'Value', 'assert', 'Callback', ImportLusUtils.get_obs_callback());
    mask.addParameter('Type', 'edit', 'Prompt', 'Observer type', 'Name', 'ObserverType', 'TypeOptions', {'Ellipsoid'}, 'Callback', ImportLusUtils.get_obs_callback(), 'Evaluate', 'off');
    set_param(observer_path, 'ForegroundColor', 'red');
    set_param(observer_path, 'BackgroundColor', 'white');

end

