function [new_ir] = stateflow_IR_pp(new_ir, output_dir, print_in_file)
% stateflow_IR_pp pre-process internal representation of stateflow. For
% example change Simulink datatypes (int32, ...) to lustre datatypes (int,
% real, bool).
% This function call SFIR_PP_config to choose which functions to call and
% in which order
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin ==0 || isempty(new_ir) || ~isa(new_ir, 'Program')
    display_msg('please provide Stateflow IR while calling stateflow_IR_pp',...
        MsgType.ERROR, 'stateflow_IR_pp', '');
    return;
end
if nargin < 2 || isempty(output_dir)
    output_dir = pwd;
end
if nargin < 3 || isempty(print_in_file)
    print_in_file = 0;
end


%% Order functions
global ordered_sfIR_pp_functions;
if isempty(ordered_sfIR_pp_functions)
    SFIR_PP_config;
end

%% sort functions calls
oldDir = pwd;
for i=1:numel(ordered_sfIR_pp_functions)
    [dirname, func_name, ~] = fileparts(ordered_sfIR_pp_functions{i});
    cd(dirname);
    fh = str2func(func_name);
    try
        display_msg(['runing ' func2str(fh)], MsgType.INFO, 'Stateflow_IRPP', '');
         new_ir = fh(new_ir);
    catch me
        display_msg(['can not run ' func2str(fh)], MsgType.ERROR, 'Stateflow_IRPP', '');
        display_msg(me.getReport(), MsgType.DEBUG, 'Stateflow_IRPP', '');
    end
    
end
cd(oldDir);
%%  Exporting the IR

if print_in_file
    json_text = json_encode(new_ir);
    json_text = regexprep(json_text, '\\/','/');
    fname = fullfile(output_dir, strcat(SFIRUtils.adapt_root_name(new_ir.name),'_SFIR_pp_tmp.json'));
    fname_formatted = fullfile(output_dir, strcat(SFIRUtils.adapt_root_name(new_ir.name),'_SFIR_pp.json'));
    fid = fopen(fname, 'w');
    if fid==-1
        display_msg(['Couldn''t create file ' fname], MsgType.ERROR, 'Stateflow_IRPP', '');
    else
        fprintf(fid,'%s\n',json_text);
        fclose(fid);
        cmd = ['cat ' fname ' | python -mjson.tool > ' fname_formatted];
        try
            [status, output] = system(cmd);
            if status~=0
                display_msg(['file is not formatted ' output], MsgType.ERROR, 'Stateflow_IRPP', '');
                fname_formatted = fname;
            end
        catch
            fname_formatted = fname;
        end
        display_msg(['IR has been written in ' fname_formatted], MsgType.RESULT, 'Stateflow_IRPP', '');
    end
end


display_msg('Done with the pre-processing', MsgType.INFO, 'Stateflow_IRPP', '');
end