classdef LustreProgram < LustreAst
    %LustreProgram
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        opens;
        nodes;
        contracts;
    end
    
    methods 
        function obj = LustreProgram(opens, nodes, contracts)
            obj.opens = opens;
            obj.nodes = nodes;
            obj.contracts = contracts;
        end
        
      
        
        function code = print_lustrec(obj)
            lines = {};
            %opens
            for i=1:numel(obj.opens)
                lines{end+1} = sprintf('#open <%s>\n', ...
                    obj.opens{i});
            end
            % contracts
            for i=1:numel(obj.contracts)
                lines{end+1} = sprintf('%s\n', ...
                    obj.contracts{i}.print_lustrec());
            end
            % modes
            for i=1:numel(obj.nodes)
                lines{end+1} = sprintf('%s\n', ...
                    obj.nodes{i}.print_lustrec());
            end
            code = MatlabUtils.strjoin(lines, '');
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec();
        end
        function code = print_zustre(obj)
            code = '';
        end
        function code = print_jkind(obj)
            code = '';
        end
        function code = print_prelude(obj)
            code = '';
        end
    end

end

