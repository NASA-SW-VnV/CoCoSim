
%% Show CEX
function show_CEX(cex_msg, cex_file_path )
    fid = fopen(cex_file_path, 'w');
    for i=1:numel(cex_msg)
        f_msg = cex_msg{i};
        display_msg(f_msg, MsgType.RESULT, 'CEX', '');
        fprintf(fid, f_msg);
    end
    fclose(fid);
end
