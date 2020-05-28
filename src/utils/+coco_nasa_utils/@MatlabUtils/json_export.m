function [status, json_fpath] = json_export(var, output_dir, json_fname)
    status = 0;
    try
        var_encoded = coco_nasa_utils.MatlabUtils.jsonencode(var);
        var_encoded = strrep(var_encoded,'\/','/');
        tmp_json_fname = strcat('tmp_', json_fname);
        tmp_json_fpath = fullfile(output_dir, tmp_json_fname);
        fid = fopen(tmp_json_fpath, 'w');
        fprintf(fid, '%s\n', var_encoded);
        fclose(fid);
        json_fpath = fullfile(output_dir, json_fname);
        cmd = ['cat ' tmp_json_fpath ' | python -mjson.tool > ' json_fpath];
        try
            [status, ~] = system(cmd);
            if status==0
                system(['rm ' tmp_json_fpath]);
            else
                copyfile(tmp_json_fpath, json_fpath);
                %             warning('Json file %s couldn''t be formatted see error:\n%s\n',...
                %                 output);
            end
        catch
            copyfile(tmp_json_fpath, json_fpath);
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'json_export', '');
        status = 1;
    end
end

