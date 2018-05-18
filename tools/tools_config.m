%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% LUSTREC, LUCTREC_INCLUDE_DIR, ZUSTRE, Z3, KIND2
% Configuration file for the backend solvers : Zustre, Kind2, JKind
% If you need CoCosim for Verification please set the backend solvers
% paths.
% You have three options:
% 1- Launch the script 'cocoSim/scripts/install_tools'
%
% 2- Put them in the default folder and you have nothing
%   to configure.
%   defaults folders are
%   Zustre : cocoSim/tools/verifiers/(osx or linux)/zustre
%   Kind2  : cocoSim/tools/verifiers/(osx or linux)/kind2
%   Lustrec: cocoSim/tools/verifiers/(osx or linux)/lustrec
%
% 3- Set your own paths by redefining the variables : ZUSTRE, LUSTREC,
%   KIND2

global tools_config_already_run;
if isempty(tools_config_already_run)
    tools_config_already_run = 0;
else
    tools_config_already_run = 1;
end
[tools_root, ~, ~] = fileparts(which('tools_config')); %fileparts(mfilename('fullpath'));
cocoSim_root = fileparts(tools_root);
if ~exist('solvers_path', 'var')
    solvers_path = fullfile(cocoSim_root, 'tools', 'verifiers');
    if ismac
        solvers_path = fullfile(solvers_path, 'osx');
        Z3Library_path = fullfile(solvers_path,'spacer', 'lib', 'libz3.dylib');
        LD_LIBRARY_PATH = 'DYLD_LIBRARY_PATH';
        
    elseif isunix
        solvers_path = fullfile(solvers_path, 'linux');
        Z3Library_path = fullfile(solvers_path,'spacer', 'lib', 'libz3.so');
        LD_LIBRARY_PATH = 'LD_LIBRARY_PATH';
    elseif ispc
        Z3Library_path = fullfile(cocosim_path, 'tools\verifiers\Z3\bin\libz3.dll');
    else
        errordlg('OS not supported yet','CoCoSim backend configuration');
    end
    OldLibPath = getenv(LD_LIBRARY_PATH);
    if ~contains(OldLibPath,Z3Library_path)
        setenv(LD_LIBRARY_PATH,[OldLibPath ':' Z3Library_path]);
    end
    oldPythonPath = getenv('PYTHONPATH');
    z3PythonPath = fullfile(solvers_path,'spacer', 'lib', 'python2.7','dist-packages');
    if ~contains(oldPythonPath, z3PythonPath)
        setenv('PYTHONPATH', [z3PythonPath ':' oldPythonPath]);
    end
end

LUSTREC = fullfile(solvers_path, 'lustrec', 'bin', 'lustrec');
%LUSTREC_OPTS defines options that should be passed to Lustrec when it is
%called. e.g. "int_div_euclidean" interprets integer division as Euclidean 
%(default : C division semantics)
LUSTREC_OPTS = '-int_div_euclidean -algebraic-loop-solve -int "long long int"';
LUSTRET = fullfile(solvers_path, 'lustrec', 'bin', 'lustret');
LUCTREC_INCLUDE_DIR = fullfile(solvers_path, 'lustrec', 'include', 'lustrec');
ZUSTRE = fullfile(solvers_path,'zustre', 'bin', 'zustre');
Z3 = fullfile(solvers_path,'spacer', 'bin', 'z3');
KIND2 = fullfile(solvers_path, 'kind2', 'bin', 'kind2');
JKIND = 'Path to Jkind binary';
SEAHORN = 'PATH';

if ~tools_config_already_run
    if ~exist(LUSTREC,'file')
        warning('LUSTREC is not found in %s, configure your path in tools_config.m', LUSTREC);
        warning('Please Ignore the previous warning if you are not going to use Zustre or Compiler Validation');
    end
    if ~exist(ZUSTRE,'file')
        warning('Zustre is not found in %s, configure your path in tools_config.m', ZUSTRE);
        warning('Please Ignore the previous warning if you are not going to use Zustre for verification');
    end
    if ~exist(Z3,'file')
        warning('Z3 is not found in %s, configure your path in tools_config.m', Z3);
        warning('Please Ignore the previous warning if you are not going to use Zustre ');
    end
    if ~exist(KIND2,'file')
        warning('KIND2 is not found in %s, configure your path in tools_config.m', KIND2);
        warning('Please Ignore the previous warning if you are not going to use Kind2 for verification');
    end
    
end
%% IKOS Configuration: WLLVM, WLLVMPP, EXTRACT_BC, IKOS
% You should be interested to configure this part only if you will use IKOS
% Install a tool called **Whole Program LLVM**: https://github.com/travitch/whole-program-llvm
% You can install it easily using pip:
% ```
% $ pip install wllvm
% ```

% put Clang path here
[status, CLANG_PATH] = system('which clang');
if isempty(status) || status~=0 || isempty(CLANG_PATH) || isnumeric(CLANG_PATH)
    CLANG_PATH = 'Path_to_llvm/bin/clang';
end
setenv('PATH',[CLANG_PATH ':' getenv('PATH')  ])

% wllvm path should contains wllvm wllvm++ and extract-bc
[status, WLLVM_PATH] = system('which wllvm');
if isempty(status) || status~=0 || isempty(WLLVM_PATH) || isnumeric(WLLVM_PATH)
    % put your wllvm path here instead of mine
    WLLVM_PATH = 'path_to_WLLVM';
end

WLLVM = fullfile(WLLVM_PATH,'wllvm');
WLLVMPP = fullfile(WLLVM_PATH,'wllvm++');
EXTRACT_BC = fullfile(WLLVM_PATH,'extract-bc');
[status, IKOS] = system('which ikos');
if isempty(status) || status~=0 || isempty(IKOS) || isnumeric(IKOS)
    IKOS = 'path_to_IKOS';
end


if ~tools_config_already_run
    if ~exist(WLLVM,'file')
        warning('WLLVM is not found in %s, configure your path in config.m', WLLVM);
        warning('Please Ignore the previous warning if you are not going to use IKOS for analyzing C code');
    end
    if ~exist(WLLVMPP,'file')
        warning('WLLVMPP is not found in %s, configure your path in config.m', WLLVMPP);
        warning('Please Ignore the previous warning if you are not going to use IKOS for analyzing C code');
    end
    if ~exist(EXTRACT_BC,'file')
        warning('EXTRACT_BC is not found in %s, configure your path in config.m', EXTRACT_BC);
        warning('Please Ignore the previous warning if you are not going to use IKOS for analyzing C code');
    end
    if ~exist(IKOS,'file')
        warning('IKOS is not found in %s, configure your path in config.m', IKOS);
        warning('Please Ignore the previous warning if you are not going to use IKOS for analyzing C code');
    end
end
%%
cocosim_version = 'v0.1';