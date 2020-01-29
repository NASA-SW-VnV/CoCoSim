%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%PP_CONFIG  This is a configuration file for CoCoSim preprocessing. You
%   will be able to choose what you want to be preprocessed or to create
%   your own pre-processing library. 
%
%   The standard pre-processing has been pulled from Github version of
%   CoCoSim,
%   it is under path CoCoSim/src/frontEnd/pp/std_pp.
%
%   We added some pre-processing functions that can be found in
%   src/frontEnd/pp/nasa_pp.
%   In order to re-use the work done in std_pp we created a symbolic folder
%   "src/frontEnd/pp/main" that combines between "std_pp" and our "nasa_pp".
%
%   If you need to pre-process a Simulink block that is not pre-processed
%   or to change how it has been pre-processed. Add your function to
%   "nasa_pp/blocks" or "std_pp/blocks" and go to "main/pp_config" and follow
%   instructions.
%% get script path
config_path = fileparts(mfilename('fullpath'));

%% TODO: add your library path or leave it use the default one.
% the default one is "main", change "main" to your library name that is under
% src/pp
addpath(genpath(fullfile(config_path, 'main')));



%% TODO: Go to 'main/pp_order.m' to configure functions orders.
if exist(fullfile(config_path, 'main/pp_order.m'), 'file')
    pp_order;
end



