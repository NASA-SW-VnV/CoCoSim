function [ ] = lustreDED(model_full_path,  const_files, lus_backend, varargin)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    global KIND2 Z3;
    if nargin < 2 || isempty(const_files)
        const_files = {};
    end
    if nargin < 3 || isempty(lus_backend)
        lus_backend = LusBackendType.KIND2;
    end
    coco_backend = CoCoBackendType.DED;
    
    if ~LusBackendType.isKIND2(lus_backend)
        display_msg(['Design error detection is only supported by KIND2 model checker.'...
            ' To set Kind2 as default one, go to tools -> CoCoSim -> Preferences -> Lustre Backend -> Kind2'],...
            MsgType.ERROR, 'toLustreVerify', '');
        return;
    end
    % Get start time
    t_start = tic;
    %% run ToLustre
    [nom_lustre_file, xml_trace, status, ~, ...
        ~, pp_model_full_path] = ...
        nasa_toLustre.ToLustre(model_full_path, const_files,...
        lus_backend, coco_backend, varargin);
    
    if status
        return;
    end
    
    %% run Verification
    
    CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    mapping_file = xml_trace.json_file_path;
    try
        fid = fopen(mapping_file);
        raw = fread(fid, inf);
        str = char(raw');
        fclose(fid);
        json = json_decode(str);
        %convert to cell if its json is struct
        if isstruct(json)
            json = num2cell(json);
        end
        nb_properties = sum(cellfun(@(x) isfield(x, 'PropertyType'), json));
    catch
        nb_properties = 1;
    end
    if isfield(CoCoSimPreferences, 'verificationTimeout')
        timeout = CoCoSimPreferences.verificationTimeout;
    else
        timeout = 120;
    end
    OPTS = ' --slice_nodes false --check_subproperties true ';
    timeout_analysis = timeout / nb_properties;
    [~, model, ~] = fileparts(pp_model_full_path);
    top_node_name = model;
    [status, kind2_out] = Kind2Utils2.runKIND2(...
        nom_lustre_file,...
        top_node_name, ...
        OPTS, KIND2, Z3, timeout, timeout_analysis);
    if status
        return;
    end
    
    try
        status = cocoSpecKind2(nom_lustre_file, mapping_file, kind2_out, false);
        if status
            return;
        end
        VerificationMenu.displayHtmlVerificationResultsCallbackCode(model)
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'toLustreVerify', '');
        display_msg('Something went wrong in Verification.', MsgType.ERROR, 'toLustreVerify', '');
    end
    %% report
    
    
    t_finish = toc(t_start);
    display_msg(sprintf('Total verification time: %f seconds', t_finish), Constants.RESULT, 'Time', '');
end
