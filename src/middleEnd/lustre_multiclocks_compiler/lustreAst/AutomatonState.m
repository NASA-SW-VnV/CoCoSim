classdef AutomatonState < LustreExpr
    %AutomatonState
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name;
        local_vars;
        strongTrans;
        weakTrans;
        body;
    end
    
    methods 
        function obj = AutomatonState(name, local_vars, strongTrans, weakTrans, body)
            obj.name = name;
            obj.local_vars = local_vars;
            obj.strongTrans = strongTrans;
            obj.weakTrans = weakTrans;
            obj.body = body;
        end
        function code = print_lustrec(obj)
            lines = {};
            lines{1} = sprintf('\tstate %s:\n', obj.name.print_lustre());
            % Strong transition
            for i=1:numel(obj.strongTrans)
                lines{end+1} = sprintf('\tunless %s\n', ...
                        obj.strongTrans{i}.print_lustre());
            end
            %local variables
            if numel(obj.local_vars) > 1
                lines{end+1} = 'var ';
                for i=1:obj.local_vars
                    lines{end+1} = sprintf('\t%s;\n', ...
                        obj.local_vars{i}.print_lustre());
                end
            end
            % body
            lines{end+1} = sprintf('\tlet\n');
            for i=1:numel(obj.body)
                lines{end+1} = sprintf('\t\t%s\n', ...
                        obj.body{i}.print_lustre());
            end
            lines{end+1} = sprintf('\ttel\n');
            % weak transition
            for i=1:numel(obj.weakTrans)
                lines{end+1} = sprintf('\tuntil %s\n', ...
                        obj.weakTrans{i}.print_lustre());
            end
            code = MatlabUtils.strjoin(lines, '');
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec();
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec();
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec();
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec();
        end
    end

end

