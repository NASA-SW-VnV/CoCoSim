%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function schema = contractToSLDVMenu(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Transform Contract to SLDV';
    schema.callback = @contractToSLDV;
end


function contractToSLDV(varargin)
    try
        model_full_path = MenuUtils.get_file_name(gcs) ;
        transformContractToSLDV( model_full_path );
    catch ME
        display_msg(ME.getReport(), MsgType.DEBUG,'IRMenu','');
        display_msg(ME.message, MsgType.ERROR,'IRMenu','');
    end
end

