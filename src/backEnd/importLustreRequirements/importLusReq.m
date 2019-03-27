%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function new_model_path = importLusReq(current_openedSS, lusFilePath, mappingPath)
    %IMPORTLUSREQ takes a Simulink model and Lustre file to import it as
    %requirement attached to the simulink model
    global LUSTREC;
    model_full_path = get_param(bdroot(current_openedSS), 'FileName');
    if nargin < 2
        errordlg('Lustre file path is required');
        return;
    end
    if  ~exist(lusFilePath, 'file')
        errordlg(sprintf('Lustre file %s can not be Found', lusFilePath));
        return;
    end
    if ~(MatlabUtils.endsWith(lusFilePath, '.lus') || MatlabUtils.endsWith(lusFilePath, '.lusi'))
        errordlg('Lustre file extension should be ".lus"');
        return;
    end
    
    if  nargin >= 3 && ~exist(mappingPath, 'file')
        errordlg(sprintf('Mapping file %s between contract variables and Simulink can not be found', lusFilePath));
        mappingPath = '';
    elseif nargin < 3
        mappingPath = '';
    end
    
    
    %[lus_dir, ~, ~] = fileparts(lusFilePath);
    
    [model_dir, file_name, ~] = fileparts(model_full_path);
    output_dir = fullfile(model_dir, 'cocosim_output', file_name);
    if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end
    
    
    % check syntax
    [~, syntax_status, output] = LustrecUtils.generate_lusi(lusFilePath, LUSTREC );
    if syntax_status && ~isempty(output)
        display_msg('Lustre Syntax check has failed for contract code. The parsing error is the following:', MsgType.ERROR, 'TOLUSTRE', '');
        [~, lustre_file_base, ~] = fileparts(lusFilePath);
        output = regexprep(output, lusFilePath, HtmlItem.addOpenFileCmd(lusFilePath, lustre_file_base));
        display_msg(output, MsgType.ERROR, 'TOLUSTRE', '');
        return;
    end
    % generate json file of lustre
    [lus_IR_path, status] = LustrecUtils.generate_emf(lusFilePath, output_dir);
    if status
        display_msg('Could not export Lustre AST.', MsgType.ERROR, 'importLusReq', '');
        return;
    end
    [new_model_path, status] = ImportLusUtils.importLustreSpec(...
        current_openedSS,...
        lus_IR_path,...
        mappingPath, ...
        1);
    if status
        return;
    end
    
end

