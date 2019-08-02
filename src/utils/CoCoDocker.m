classdef CoCoDocker
    % COCODOCKER manage docker containers.
    %% example using the API
    % sharedFolder = '/path/to/cocosim_result/absolute'
    % CoCoDocker.start(sharedFolder)
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
        function c_name = getCurrentContainerName(restart, kill)
            persistent cname;
            if isempty(cname)
                cname = '';
            end
            
            if nargin < 1
                restart = false;
            end
            if nargin < 2
                kill = false;
            end
            
            if restart
                cname = strcat('c', strrep(num2str(rand(1)), '.', ''));
            end
            c_name = cname;
            if kill
                cname = '';
            end
        end
        
        function [c_name, errCode, stdout] = start(sharedFolder)
            c_name = CoCoDocker.getCurrentContainerName(true);
            [errCode, stdout] = system(sprintf('docker run -d --name=%s -v %s:/lus cocosim/lustre', ...
                c_name, sharedFolder));
        end
        
        function [errCode, stdout] = cp(dockerPath, hostPath)
            c_name = CoCoDocker.getCurrentContainerName();
            [errCode, stdout] = system(sprintf('docker cp %s:%s %s', ...
                c_name, dockerPath, hostPath));
        end 
        
        function [errCode, stdout] = stop()
            c_name = CoCoDocker.getCurrentContainerName(false, true);
            [errCode, stdout] = system(sprintf('docker kill %s; docker rm %s', ...
                c_name, c_name));
        end 
        
        function [errCode, stdout] = exec(sharedFolder, cmd)
            c_name = CoCoDocker.getCurrentContainerName();
            if isempty(c_name)
                [c_name, errCode, stdout] = CoCoDocker.start(sharedFolder);
                if errCode
                    return;
                end
            end
            [errCode, stdout] = system(sprintf('docker exec %s bash -c ''%s''', ...
                c_name, cmd));
        end
        
        
    end
end

