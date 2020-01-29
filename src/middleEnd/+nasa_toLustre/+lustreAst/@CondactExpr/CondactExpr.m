classdef CondactExpr < nasa_toLustre.lustreAst.NodeCallExpr
    %NodeCallExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    properties
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

