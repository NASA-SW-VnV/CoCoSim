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
function [new_ir, status] = stateflow_IR_pp(old_ir, print_in_file, output_dir)
    % stateflow_IR_pp pre-process internal representation of stateflow. For
    % example change Simulink datatypes (int32, ...) to lustre datatypes (int,
    % real, bool).
    % This function call SFIR_PP_config to choose which functions to call and
    % in which order

    status = 0;
    if nargin < 3 || isempty(output_dir)
        output_dir = pwd;
    end
    MatlabUtils.mkdir(output_dir);
    if nargin < 2 || isempty(print_in_file)
        print_in_file = 0;
    end

    if nargin ==0 || isempty(old_ir)
        display_msg('please provide Stateflow IR while calling stateflow_IR_pp',...
            MsgType.ERROR, 'stateflow_IR_pp', '');
        return;
    else
        new_ir = old_ir;
    end


    %% Order functions
    global ordered_sfIR_pp_functions;
    if isempty(ordered_sfIR_pp_functions)
        nasa_toLustre.IR_pp.stateflow_IR_pp.SFIR_PP_config;
    end

    % transform Program to struct
    %% sort functions calls
    for i=1:numel(ordered_sfIR_pp_functions)
        [dirname, func_name, ~] = fileparts(ordered_sfIR_pp_functions{i});
        package_prefix = MatlabUtils.getPackagePrefix(dirname, func_name);
        fh = str2func(sprintf('%s.%s', package_prefix, func_name));
        try
            display_msg(['runing ' func2str(fh)], MsgType.INFO, 'Stateflow_IRPP', '', 1);
            [new_ir, status] = fh(new_ir);
            if status
                 display_msg('Stateflow_IR_PP has been interrupted', MsgType.ERROR, 'Stateflow_IRPP', '');
                 return;
            end
        catch me
            display_msg(['can not run ' func2str(fh)], MsgType.ERROR, 'Stateflow_IRPP', '');
            display_msg(me.getReport(), MsgType.DEBUG, 'Stateflow_IRPP', '');
        end

    end
    %%  Exporting the IR

    if print_in_file
        try
            json_text = MatlabUtils.jsonencode(new_ir);
            json_text = regexprep(json_text, '\\/','/');
            fname = fullfile(output_dir, sprintf('%s_SFIR_pp_tmp.json', nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.adapt_root_name(new_ir.Name{1})));
            fname_formatted = fullfile(output_dir, sprintf('%s_SFIR_pp.json', nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.adapt_root_name(new_ir.Name{1})));
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
        catch ME
            display_msg(['Couldn''t export Stateflow to IR'], MsgType.WARNING, 'Stateflow_IRPP', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'Stateflow_IRPP', '');
        end
    end


    display_msg('Done with the SFIR pre-processing', MsgType.INFO, 'Stateflow_IRPP', '');
end
