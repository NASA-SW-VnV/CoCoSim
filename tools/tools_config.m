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
%   cocoSim/tools/verifiers/(osx or linux)/bin
%   cocoSim/tools/verifiers/(osx or linux)/include
%   cocoSim/tools/verifiers/(osx or linux)/lib
%
% 3- Set your own paths by redefining the variables : ZUSTRE, LUSTREC,
%   KIND2

global tools_config_already_run LUSTREC LUSTREC_OPTS LUSTRET ...
    LUCTREC_INCLUDE_DIR ZUSTRE Z3 KIND2 JKIND JLUSTRE2KIND SEAHORN...
    WLLVM WLLVMPP EXTRACT_BC IKOS cocosim_version;
if isempty(tools_config_already_run) 
    tools_config_already_run = false;
end
if tools_config_already_run && ~isempty(LUSTREC) && ~isempty(KIND2) && ~isempty(Z3)
    %already run
else
    [tools_root, ~, ~] = fileparts(which('tools_config')); %fileparts(mfilename('fullpath'));
    cocoSim_root = fileparts(tools_root);
    % for MatlabUtils
    addpath(fullfile(cocoSim_root, 'src', 'utils'));
    addpath(fullfile(cocoSim_root, 'src', 'external', 'cocosim_iowa', 'utils'));
    if ~exist('solvers_path', 'var')
        verifiers_path = fullfile(cocoSim_root, 'tools', 'verifiers');
        solvers_path = verifiers_path;
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
        if ~MatlabUtils.contains(OldLibPath,Z3Library_path)
            setenv(LD_LIBRARY_PATH,[OldLibPath ':' Z3Library_path]);
        end
        oldPythonPath = getenv('PYTHONPATH');
        z3PythonPath = fullfile(solvers_path,'spacer', 'lib', 'python2.7','dist-packages');
        if ~MatlabUtils.contains(oldPythonPath, z3PythonPath)
            setenv('PYTHONPATH', [z3PythonPath ':' oldPythonPath]);
        end
    end
    
    LUSTREC = fullfile(solvers_path, 'bin', 'lustrec');
    %LUSTREC_OPTS defines options that should be passed to Lustrec when it is
    %called. e.g. "int_div_euclidean" interprets integer division as Euclidean
    %(default : C division semantics)
    LUSTREC_OPTS = '-int_div_euclidean -algebraic-loop-solve -int "long long int"';
    LUSTRET = fullfile(solvers_path, 'bin', 'lustret');
    LUCTREC_INCLUDE_DIR = fullfile(solvers_path, 'include', 'lustrec');
    ZUSTRE = fullfile(solvers_path, 'bin', 'zustre');
    Z3 = fullfile(solvers_path,'z3', 'bin', 'z3');
    KIND2 = fullfile(solvers_path, 'bin', 'kind2');
    JKIND = fullfile(verifiers_path, 'jkind', 'jkind');
    JLUSTRE2KIND = fullfile(verifiers_path, 'jkind', 'jlustre2kind');
    SEAHORN = 'PATH';
    
    if ~tools_config_already_run
        if ~exist(LUSTREC,'file')
            display_msg(...
                sprintf('LUSTREC is not found in %s, configure your path in tools_config.m', LUSTREC), ...
                MsgType.WARNING, 'tools_config', '');
            display_msg('You can ignore the previous warning if you are not going to use Zustre or Compiler Validation', ...
                MsgType.WARNING, 'tools_config', '');
        end
        if ~exist(ZUSTRE,'file')
            display_msg(...
                sprintf('Zustre is not found in %s, configure your path in tools_config.m', ZUSTRE), ...
                MsgType.WARNING, 'tools_config', '');
            display_msg('You can ignore the previous warning if you are not going to use Zustre for verification', ...
                MsgType.WARNING, 'tools_config', '');
        end
        if ~exist(Z3,'file')
            display_msg(...
                sprintf('Z3 is not found in %s, configure your path in tools_config.m', Z3), ...
                MsgType.WARNING, 'tools_config', '');
            display_msg('You can ignore the previous warning if you are not going to use Zustre ', ...
                MsgType.WARNING, 'tools_config', '');
        end
        if ~exist(KIND2,'file')
            display_msg(...
                sprintf('KIND2 is not found in %s, configure your path in tools_config.m', KIND2), ...
                MsgType.WARNING, 'tools_config', '');
            display_msg('You can ignore the previous warning if you are not going to use Kind2 for verification', ...
                MsgType.WARNING, 'tools_config', '');
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
            display_msg(...
                sprintf('WLLVM is not found in %s, configure your path in config.m', WLLVM), ...
                MsgType.WARNING, 'tools_config', '');
            display_msg('You can ignore the previous warning if you are not going to use IKOS for analyzing C code', ...
                MsgType.WARNING, 'tools_config', '');
        end
        if ~exist(WLLVMPP,'file')
            display_msg(...
                sprintf('WLLVMPP is not found in %s, configure your path in config.m', WLLVMPP), ...
                MsgType.WARNING, 'tools_config', '');
            display_msg('You can ignore the previous warning if you are not going to use IKOS for analyzing C code', ...
                MsgType.WARNING, 'tools_config', '');
        end
        if ~exist(EXTRACT_BC,'file')
            display_msg(...
                sprintf('EXTRACT_BC is not found in %s, configure your path in config.m', EXTRACT_BC), ...
                MsgType.WARNING, 'tools_config', '');
            display_msg('You can ignore the previous warning if you are not going to use IKOS for analyzing C code', ...
                MsgType.WARNING, 'tools_config', '');
        end
        if ~exist(IKOS,'file')
            display_msg(...
                sprintf('IKOS is not found in %s, configure your path in config.m', IKOS), ...
                MsgType.WARNING, 'tools_config', '');
            display_msg('You can ignore the previous warning if you are not going to use IKOS for analyzing C code', ...
                MsgType.WARNING, 'tools_config', '');
        end
    end
    %%
    cocosim_version = 'v0.1';
    tools_config_already_run = true;
end