%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef MenuUtils
    %MenuUtils contains functions common to Menu functions
    
    properties
    end
    
    methods (Static = true)
        
        
        %% get function handle from its path
        handle = funPath2Handle(fullpath)
        
        output = addTryCatch(callbackInfo)

        handleExceptionMessage(e, source)
        %% get file name from the current opened Simulink model.
        [fpath, fname] = get_file_name(gcs)

        %% add PP warning
        add_pp_warning(model_path)

        %% Create html page with title and items list.
        html_path = createHtmlList(title, items_list, html_path)

        html_path = createHtmlListUsingHTMLITEM(title, items_list, html_path, model)

        metaInfo = getModelInfo(title, model)

    end
    
end

