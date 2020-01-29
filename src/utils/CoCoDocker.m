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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%classdef CoCoDocker
    % COCODOCKER manage docker containers.
    %% example using the API
    % sharedFolder = '/path/to/cocosim_result/absolute'
    % CoCoDocker.start(sharedFolder)  % optionnal
    % CoCoDocker.exec(sharedFolder, 'lustrec -node absolute_PP -int="long long int" absolute_PP.LUSTREC.lus')
    % CoCoDocker.exec(sharedFolder, 'make -f absolute_PP.LUSTREC.makefile')
    % CoCoDocker.exec(sharedFolder, '/lus/absolute_PP.LUSTREC_absolute_PP < /lus/absolute_PP_input_values > absolute_PP_output_values')
    % CocoDocker.stop()
    %% in terminal (example)
    % docker run -d --name=toto -v $(pwd):/lus cocotest
    % docker exec toto lustrec -node absolute_PP -int="long long int" absolute_PP.LUSTREC.lus
    % docker exec toto make -f absolute_PP.LUSTREC.makefile
    % docker exec toto bash -c '/lus/absolute_PP.LUSTREC_absolute_PP < /lus/absolute_PP_input_values > absolute_PP_output_values'
    % docker stop toto && docker rm toto
    properties
    end
    
    methods(Static)
        function c_name = getCurrentContainerName(sharedFolder, kill)
            global DOCKER
            if isempty(DOCKER)
                tools_config;
            end
            persistent cnameMap;
            
            if nargin < 2
                kill = false;
            end
            
            if isempty(cnameMap) || ~cnameMap.isKey(sharedFolder)
                c_name = strcat('c', strrep(num2str(rand(1)), '.', ''));
                if isempty(cnameMap)
                	cnameMap = containers.Map(sharedFolder, c_name);
                else
                    cnameMap(sharedFolder, c_name);
                end
                [errCode, stdout] = system(sprintf('%s run -d --name=%s -v %s:/lus cocosim/lustre', ...
                    DOCKER, c_name, sharedFolder));
            end
            
            c_name = cnameMap(sharedFolder);
            if kill
                cnameMap.remove(sharedFolder);
            end
            
        end
        
        function c_name = start(sharedFolder)
            global DOCKER
            if isempty(DOCKER)
                tools_config;
            end
            c_name = CoCoDocker.getCurrentContainerName(sharedFolder);
        end
        
        function [errCode, stdout] = cp(dockerPath, hostPath)
            global DOCKER
            if isempty(DOCKER)
                tools_config;
            end
            c_name = CoCoDocker.getCurrentContainerName(sharedFolder);
            [errCode, stdout] = system(sprintf('%s cp %s:%s %s', ...
                DOCKER, c_name, dockerPath, hostPath));
        end
        
        function [errCode, stdout] = stop(sharedFolder)
            global DOCKER
            if isempty(DOCKER)
                tools_config;
            end
            c_name = CoCoDocker.getCurrentContainerName(sharedFolder, true);
            [errCode, stdout] = system(sprintf('%s kill %s; %s rm %s', ...
                DOCKER, c_name, DOCKER, c_name));
        end
        
        function [errCode, stdout] = exec(sharedFolder, cmd)
            global DOCKER
            if isempty(DOCKER)
                tools_config;
            end
            c_name = CoCoDocker.getCurrentContainerName(sharedFolder);
            [errCode, stdout] = system(sprintf('%s exec %s bash -c ''%s''', ...
                DOCKER, c_name, cmd));
        end
        
        
    end
end

