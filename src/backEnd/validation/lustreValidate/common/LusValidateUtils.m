classdef LusValidateUtils
    %UTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        %%
        %Adapte Simulink blocks name to Lustre names
        function str_out = name_format(str)
            newline = sprintf('\n');
            str_out = strrep(str, newline, '');
            str_out = strrep(str_out, ' ', '');
            str_out = strrep(str_out, '-', '_minus_');
            str_out = strrep(str_out, '+', '_plus_');
            str_out = strrep(str_out, '*', '_mult_');
            str_out = strrep(str_out, '.', '_dot_');
            str_out = strrep(str_out, '#', '_sharp_');
            str_out = strrep(str_out, '(', '_lpar_');
            str_out = strrep(str_out, ')', '_rpar_');
            str_out = strrep(str_out, '[', '_lsbrak_');
            str_out = strrep(str_out, ']', '_rsbrak_');
            str_out = strrep(str_out, '{', '_lbrak_');
            str_out = strrep(str_out, '}', '_rbrak_');
            %hamza modification
            str_out = strrep(str_out, ',', '_comma_');
            %             str_out = strrep(str_out, '/', '_slash_');
            str_out = strrep(str_out, '=', '_equal_');
            
            str_out = regexprep(str_out, '/(\d+)', '/_$1');
            str_out = regexprep(str_out, '[^a-zA-Z0-9_/]', '_');
        end
        
        
       
       
        
        %% Try to calculate Block sample time using GCD
        function st = get_BlockDiagram_SampleTime(file_name)
            warning off;
            ts = Simulink.BlockDiagram.getSampleTimes(file_name);
            warning on;
            st = 1;
            for t=ts
                if ~isempty(t.Value) && isnumeric(t.Value)
                    tv = t.Value(1);
                    if ~(isnan(tv) || tv==Inf)
                        st = gcd(st*100,tv*100)/100;
                        
                    end
                end
            end
            
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
        function [ Lustre_type, initial_value ] = get_lustre_dt( stateflow_Type, data_name )
            if strcmp(stateflow_Type, 'real') || strcmp(stateflow_Type, 'int') || strcmp(stateflow_Type, 'bool')
                Lustre_type = stateflow_Type;
            else
                if strcmp(stateflow_Type, 'logical') || strcmp(stateflow_Type, 'boolean')
                    Lustre_type = 'bool';
                    initial_value = 'false';
                elseif strncmp(stateflow_Type, 'int', 3) || strncmp(stateflow_Type, 'uint', 4) || strncmp(stateflow_Type, 'fixdt(1,16,', 11) || strncmp(stateflow_Type, 'sfix64', 6)
                    Lustre_type = 'int';
                    initial_value = '0';
                elseif contains(stateflow_Type,'Inherit') && nargin==2
                    try
                        var = evalin('base',data_name);
                        [ Lustre_type, initial_value ] = get_lustre_dt( var.DataType, data_name );
                    catch ME
                        msg = ['Parameter :' char(data_name) ' declared as type :"' char(stateflow_Type) '" does not exit in workspace base.\n',...
                            'Make sure you set all model parameters in workspace before you run the tool.\n'];
                        causeException = MException('simulinkParameter:UnknownData',msg);
                        ME = addCause(ME,causeException);
                        rethrow(ME)
                    end
                else
                    Lustre_type = 'real';
                    initial_value = '0.0';
                end
            end
        end
        
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

