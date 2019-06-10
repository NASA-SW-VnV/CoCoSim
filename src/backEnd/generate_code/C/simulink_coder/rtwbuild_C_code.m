%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate C code from lustre file using lustrec tool.
function rtwbuild_C_code(model_full_path, output_dir)

[mdl_path, file_name, ~] = fileparts(model_full_path);
if nargin < 2
    output_dir = fullfile(mdl_path, strcat(file_name, '_SimulinkCoder'));
end
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
PWD = pwd;
cd(output_dir);

if license('checkout', 'real-time_workshop') ~= 1
     display_msg('Simulink Coder is not installed. This functionality need Simulind coder to be installed', ...
        MsgType.ERROR,'rtwbuild_C_code','');
    return;
end

load_system(model_full_path)
disp('Generating C code... Please wait until it finishes.');
try
    rtwbuild(file_name,'generateCodeOnly', true);
catch ME
    display_msg(ME.getReport(), ...
        MsgType.DEBUG,'rtwbuild_C_code','');
    display_msg('Please verify you can build your model', ...
        MsgType.ERROR,'rtwbuild_C_code','');
    cd(PWD)
    return;
end
display_msg(['generation code is successfully completed in ' output_dir], ...
            Constants.RESULT,'IKOS','');
cd(PWD);
end

