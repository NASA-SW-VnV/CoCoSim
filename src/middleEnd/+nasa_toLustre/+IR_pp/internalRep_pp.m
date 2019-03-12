function [ new_ir, ir_handle_struct_map ] = internalRep_pp( new_ir, json_export, output_dir )
    %IR_PP pre-process the IR for cocoSim to adapte the IR to the compiler or
    %make some analysis in the IR level.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~exist('json_export', 'var')
        json_export = 0;
    end
    if ~exist('output_dir', 'var')
        output_dir = fileparts(new_ir.meta.file_path);
    end
    %% apply functions in library folder
    [ir_pp_root, ~, ~] = fileparts(mfilename('fullpath'));
    lib_dir = fullfile(ir_pp_root, '+lib');
    functions = dir(fullfile(lib_dir , '*.m'));
    oldDir = pwd;
    if isstruct(functions) && isfield(functions, 'name')
        cd(lib_dir);
        for i=1:numel(functions)
            display_msg(['runing ' functions(i).name(1:end-2)], MsgType.INFO, 'internalRep_pp', '');
            fun_name = sprintf('nasa_toLustre.IR_pp.lib.%s', functions(i).name(1:end-2));
            fh = str2func(fun_name);
            new_ir = fh(new_ir);
        end
        cd(oldDir);
    end
    [~, model_name, ~] = fileparts(new_ir.meta.file_path);
    ir_handle_struct_map = get_ir_handle_struct_map(new_ir, model_name);
    
    %% export json
    if json_export
        try
            ir_encoded = json_encode(new_ir);
            ir_encoded = strrep(ir_encoded,'\/','/');
            mdl_name = '';
            if nargin < 3
                if isfield(new_ir, 'meta') && isfield(new_ir.meta, 'file_path')
                    [output_dir, mdl_name, ~] = fileparts(new_ir.meta.file_path);
                else
                    output_dir = oldDir;
                end
            else
                if isfield(new_ir, 'meta') && isfield(new_ir.meta, 'file_path')
                    [~, mdl_name, ~] = fileparts(new_ir.meta.file_path);
                end
            end
            
            json_name = 'IR_pp_tmp.json';
            json_path = fullfile(output_dir, json_name);
            fid = fopen(json_path, 'w');
            fprintf(fid, '%s\n', ir_encoded);
            fclose(fid);
            
            new_path = fullfile(output_dir, strcat('IR_pp_', mdl_name,'.json'));
            cmd = ['cat ' json_path ' | python -mjson.tool > ' new_path];
            try
                [status, output] = system(cmd);
                if status==0
                    system(['rm ' json_path]);
                else
                    warning('IR_PP json file couldn''t be formatted see error:\n%s\n',...
                        output);
                end
            catch
            end
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'internalRep_pp', '');
        end
    end
    display_msg('Done with the IR pre-processing', MsgType.INFO, 'internalRep_pp', '');
    
end

function handle_struct_map = get_ir_handle_struct_map(ir_struct, block_name)
    
    handle_struct_map = containers.Map('KeyType','double', 'ValueType','any');
    
    
    if isfield(ir_struct.(block_name),'Handle')
        handle_struct_map(ir_struct.(block_name).Handle) = ir_struct.(block_name);
    end
    
    
    if isfield(ir_struct.(block_name), 'Content')
        fields = fieldnames(ir_struct.(block_name).Content);
        for i=1:numel(fields)
            handle_struct_map_i = get_ir_handle_struct_map(ir_struct.(block_name).Content, fields{i});
            handle_struct_map = [handle_struct_map; handle_struct_map_i];
        end
    end
    
end