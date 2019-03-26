%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function new_model_path = importLusReq(model_full_path, lusFilePath)
    %IMPORTLUSREQ takes a Simulink model and Lustre file to import it as
    %requirement attached to the simulink model
    if nargin < 2
        errordlg('Lustre file path is required');
        return;
    end
    if  ~exist(lusFilePath, 'file') 
        errordlg(sprintf('Lustre file %s can not be Found', lusFilePath));
        return;
    end
    if ~(MatlabUtils.endsWith(lusFilePath, '.lus') || MatlabUtils.endsWith(lusFilePath, '.lusi'))
        errordlg('Lustre file extension is ".lus"');
        return;
    end
    [lus_dir, ~, ~] = fileparts(lusFilePath);
    
    [model_dir, file_name, ~] = fileparts(model_full_path);
    output_dir = fullfile(model_dir, 'cocosim_output', file_name);
    if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end
    
    [lus_IR_path, status] = LustrecUtils.generate_emf(lusFilePath, lus_dir);
    if status
        display_msg('Could not export Lustre AST.', MsgType.ERROR, 'importLusReq', '');
        return;
    end
    [new_model_path, status] = ImportLusUtils.importLustreSpec(...
        model_full_path,...
        lus_IR_path,...
        [], ...
        1);
    if status
        return;
    end
    
end

