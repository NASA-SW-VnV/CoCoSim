classdef LusValidateUtils
    %UTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        %%
        %Adapte Simulink blocks name to Lustre names
        function str_out = name_format(str)
            str_out = SLX2LusUtils.name_format(str);
        end

        %% Generate random vectors
        function vector = construct_random_integers(nb_iterations, IMIN, IMAX, dt, dim)
            if numel(dim)==1
                vector = randi([IMIN, IMAX], [nb_iterations,dim],dt);
            else
                vector = randi([IMIN, IMAX], [dim,nb_iterations],dt);
            end
        end
        
        function vector = construct_random_booleans(nb_iterations, IMIN, IMAX, dim)
            vector = boolean(LusValidateUtils.construct_random_integers(nb_iterations, IMIN, IMAX, 'uint8',dim));
        end
        
        function vector = construct_random_doubles(nb_iterations, IMIN, IMAX,dim)
            if numel(dim)==1
                vector = double(IMIN + (IMAX-IMIN).*rand([nb_iterations,dim]));
            else
                vector = double(IMIN + (IMAX-IMIN).*rand([dim, nb_iterations]));
            end
        end
        
       
        
        
        %% from Simulink dataType to Lustre DataType
    
        function slx_dt = get_slx_dt(lus_dt)
            if strcmp(lus_dt, 'bool')
                slx_dt = 'boolean';
            elseif strcmp(lus_dt, 'int')
                slx_dt = 'int32';
            elseif strcmp(lus_dt, 'real')
                slx_dt = 'double';
            else
                slx_dt = lus_dt;
            end
        end
      
    end
    
end

