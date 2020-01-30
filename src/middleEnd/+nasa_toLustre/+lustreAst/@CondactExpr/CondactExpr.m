classdef CondactExpr < nasa_toLustre.lustreAst.NodeCallExpr
    %NodeCallExpr

    properties
    end
    
    methods
        function obj = CondactExpr(args)
            obj = obj@nasa_toLustre.lustreAst.NodeCallExpr('condact', args);
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            % we don't include "condact" as node call, it's lustre operator
            nodesCalled = getNodesCalled@nasa_toLustre.lustreAst.NodeCallExpr(obj);
            nodesCalled = nodesCalled(~strcmp(nodesCalled, 'condact'));
        end
    end
end

