%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ new_ir, ir_handle_struct_map, ir_json_path ] = internalRep_pp( new_ir, json_export, output_dir )
    %IR_PP pre-process the IR for cocoSim to adapte the IR to the compiler or
    %make some analysis in the IR level.

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
            display_msg(['runing ' functions(i).name(1:end-2)], MsgType.INFO, 'internalRep_pp', '', 1);
            fun_name = sprintf('nasa_toLustre.IR_pp.lib.%s', functions(i).name(1:end-2));
            fh = str2func(fun_name);
            new_ir = fh(new_ir);
        end
        cd(oldDir);
    end
    [~, model_name, ~] = fileparts(new_ir.meta.file_path);
    ir_handle_struct_map = get_ir_handle_struct_map(new_ir, model_name);
    ir_json_path = '';
    %% export json
    if json_export
        try
            ir_encoded = MatlabUtils.jsonencode(new_ir);
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
            
            ir_json_path = fullfile(output_dir, strcat('IR_pp_', mdl_name,'.json'));
            cmd = ['cat ' json_path ' | python -mjson.tool > ' ir_json_path];
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