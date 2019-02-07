
function new_mcdc_file = adapt_lustre_file(mcdc_file, dest)
    % adapt lustre code
    if nargin < 2
        dest = '';
    end
    if ~exist(mcdc_file, 'file')
        display_msg(['File not found ' mcdc_file], MsgType.ERROR, 'adapt_lustre_file', '');
        return;
    end
    [output_dir, lus_file_name, ~] = fileparts(mcdc_file);
    new_mcdc_file = fullfile(output_dir,strcat( lus_file_name, '_adapted.lus'));
    fid = fopen(new_mcdc_file, 'w');
    if fid > 0
        fprintf(fid, '%s', LustrecUtils.adapt_lustre_text(fileread(mcdc_file), dest));
        fclose(fid);
    else
        new_mcdc_file = mcdc_file;
    end
end
