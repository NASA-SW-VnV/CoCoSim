%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% for compatibility with old cocosim libraries, we add this global
% variable.
global cocosim_config_already_run;
if isempty(cocosim_config_already_run)
    cocosim_config_already_run = false;
end
%% add paths
[cocoSim_root, ~, ~] = fileparts(mfilename('fullpath'));
warning off
%add all folders except tools sub-folders
addpath(genpath(cocoSim_root));
rmpath(genpath(fullfile(cocoSim_root, 'tools')));
%add only tools not its sub-folders
addpath(fullfile(cocoSim_root, 'tools'));
% addpath(genpath(fullfile(cocoSim_root, 'libs')));
% addpath(genpath(fullfile(cocoSim_root, 'scripts')));
% addpath(genpath(fullfile(cocoSim_root, 'src')));
% addpath(fullfile(cocoSim_root, 'tools'));
if cocosim_config_already_run
    % only tools_config is needed from old compiler
    tools_config;
else
    %% First configuration, Zustre, Kind2 and Lustrec
    % Go to tools/tools_config and follow instructions
    tools_config;
    
    
    %% Second configuration Pre-processing
    % Go to src/pp/pp_config and follow instructions
    pp_config;
    fprintf('\n\t Click <a href="matlab: pp_user_config">here</a> to change pre-processing configuration.\n');
    
    %% IR config
    
    ir_utils_path = fullfile(cocoSim_root, 'src', 'frontEnd', 'IR', 'utils');
    json_encode_file = 'json_encode';
    json_decode_file = 'json_decode';
    
    if ismac
        json_encode_file = fullfile(ir_utils_path, 'json_encode.mexmaci64');
        json_decode_file = fullfile(ir_utils_path, 'json_decode.mexmaci64');
    elseif isunix
        json_encode_file = fullfile(ir_utils_path, 'json_encode.mexa64');
        json_decode_file = fullfile(ir_utils_path, 'json_decode.mexa64');
    elseif ispc
        json_encode_file = fullfile(ir_utils_path, 'json_encode.mexw64');
        json_decode_file = fullfile(ir_utils_path, 'json_decode.mexw64');
    end
    need_to_compile = true;
    if  exist(json_encode_file, 'file') && exist(json_decode_file, 'file')
        try
            json_decode('{"a":1, "b":2}');
            s = struct('a', 1, 'b', 2);
            json_encode(s);
            need_to_compile = false;
        catch
        end
    end
    if need_to_compile
        if exist(fullfile(ir_utils_path, 'make.m'), 'file')
            PWD = pwd;
            cd(ir_utils_path);
            try
                make
            catch  ME
                display_msg(ME.getReport(), MsgType.ERROR, 'cocosim_config', '');
            end
            cd(PWD);
        end
    end
    
    %% Java external libraries
    matlabParser = fullfile(cocoSim_root, 'src','frontEnd', 'IR',...
        'Matlab_IR', 'Matlab-Parser.jar');
    
    if exist(matlabParser, 'file')
        javaaddpath(matlabParser);
    end
    
    warning on
    cocosim_config_already_run = true;
end