%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ failed ] = lustreDED(model_full_path,  const_files, lus_backend, varargin)

    global KIND2 Z3;
    if nargin < 2 || isempty(const_files)
        const_files = {};
    end
    if nargin < 3 || isempty(lus_backend)
        lus_backend = LusBackendType.KIND2;
    end
    
    if isempty(KIND2)
        tools_config;
    end
    if LusBackendType.isKIND2(lus_backend) && ~exist(KIND2,'file')
        errordlg(sprintf('KIND2 model checker is not found in %s. Please set KIND2 path in tools_config.m', KIND2));
        return;
    elseif ~LusBackendType.isKIND2(lus_backend)
        errordlg('Only KIND2 currently is supported for Design Error Detection. To change Lustre model checker go to Tools -> CoCoSim -> Preferences');
        return;
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
    [nom_lustre_file, xml_trace, failed, ~, ...
        ~, pp_model_full_path] = ...
        nasa_toLustre.ToLustre(model_full_path, const_files,...
        lus_backend, coco_backend, varargin);
    
    if failed
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
    [failed, kind2_out] = Kind2Utils2.runKIND2(...
        nom_lustre_file,...
        top_node_name, ...
        OPTS, KIND2, Z3, timeout, timeout_analysis);
    if failed
        return;
    end
    
    try
        [failed, verificationResults] = cocoSpecKind2(nom_lustre_file, mapping_file, kind2_out, false);
        if failed
            return;
        end
        if ~isempty(verificationResults)
            % load model if not already loaded
            try load_system(pp_model_full_path);catch, end
            VerificationMenu.displayHtmlVerificationResultsCallbackCode(model, verificationResults);
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'toLustreVerify', '');
        display_msg('Something went wrong in Verification.', MsgType.ERROR, 'toLustreVerify', '');
    end
    %% report
    
    
    t_finish = toc(t_start);
    display_msg('Design Error Detection completed', Constants.RESULT, 'lustreDED', '');
    display_msg(sprintf('Total verification time: %f seconds', t_finish), Constants.RESULT, 'Time', '');
end
