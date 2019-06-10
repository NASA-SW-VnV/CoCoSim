function set_mask_parameters(observer_path)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    load_system(which('CoCoSimSpecification.slx'));
    originla_mask = Simulink.Mask.get(get_param('CoCoSimSpecification/contract', 'Handle'));
    mask = Simulink.Mask.create(observer_path);
    mask.copy(originla_mask);
end

