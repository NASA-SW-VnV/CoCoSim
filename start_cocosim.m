function start_cocosim(  )
%START_COCOSIM Summary of this function goes here
%   Detailed explanation goes here

disp('**********************************')
disp('  WELCOME TO COCOSIM (NASA Ames)  ')
disp('**********************************')
disp('... Starting cocoSim configuration')
cocosim_config;
sl_refresh_customizations;
disp('... Configuration is Done');
example_path = fullfile(cocoSim_root, 'test', 'properties', 'safe_1.mdl');
fprintf('\n\t Click <a href="matlab: open %s">here</a> to start with a simple verification example.\n', example_path);
end

