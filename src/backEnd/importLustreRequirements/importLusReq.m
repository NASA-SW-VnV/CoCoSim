function new_model_path = importLusReq(model_full_path, LusFilePath, Traceability)
%IMPORTLUSREQ Summary of this function goes here
%   Detailed explanation goes here
if nargin < 3
    errordlg('Lustre file and traceability are required');
    return;
else
    if  ~exist(LusFilePath, 'file') || ~exist(Traceability, 'file')
        errordlg('Lustre file or traceability can not be Found');
        return;
    else
        if ~MatlabUtils.endsWith(LusFilePath, '.lus') || ~MatlabUtils.endsWith(Traceability, '.xml')
            errordlg('Lustre file extension is ".lus", traceability extension is ".xml"');
            return;
        else
            com.mathworks.mlservices.MatlabDesktopServices.getDesktop.closeGroup('Web Browser')
        end
    end
end
[model_dir, file_name, ~] = fileparts(model_full_path);
output_dir = fullfile(model_dir, 'cocosim_output', file_name);
if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end

[lus_IR_path, status] = LustrecUtils.generate_emf(LusFilePath, output_dir);
if status
    return;
end
open(which(strcat(file_name, '_PP.mdl')))
% [new_model_path, status] = ImportLusUtils.importLustreSpec(...
%     model_full_path,...
%     lus_IR_path,...
%     Traceability, ...
%     0);
% if status
%     return;
% end

end

