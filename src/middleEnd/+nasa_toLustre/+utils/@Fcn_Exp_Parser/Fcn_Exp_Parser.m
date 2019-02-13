
classdef Fcn_Exp_Parser
    %Fcn_Exp_Parser generates a tree from a mathematical expression in Fcn
    %Block. Fcn Block in Simulink has limited grammar.
    %This function is parsing an expression from left to right. It is not
    %respecting the order of arithmetic operations. 
    %e.g. 3*2 > x*4 => {'Mult', '3', {'>', '2'. {'Mult', 'x', '4'}}}

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods(Static)
        [tree, status, unsupportedExp] = parse(exp)
        
        %%
        [tree, status, expr] = parseE(e)
        
        %%
        [tree, expr, isAssignement] = parseEA(expr)

        %% !
        [tree, expr] = parseEN(expr)
        
        [tree, expr] = parseUnaryMinus(expr)

        %% *, /, ^
        [tree, expr] = parseEM2(expr, sym1)

        [tree, expr] = parseEM(expr)
        
        [tree, expr] = parseEP(expr)
        
        %% Number, call, ()
        [tree, expr] = parseSE(expr)
  
        %% Elementary Pasers
        %
        [tree, expr] = parsePar(expr)
        
        [tree, expr] = parseNum(expr)

        %f(x)
        [tree, expr] = parseFunc(expr)

        %u[2]
        [tree, expr] = parseArray(expr)
        
        [tree, expr] = parseArgs(tree, expr, lpar, rpar)
        
        [tree, expr] = parseVar(expr)
        
        [tree, expr] = parsePlus(expr)

        [tree, expr] = parsePlusPlus(expr)

        [tree, expr] = parseMinusMinus(expr)
        
        [tree, expr] = parseMinus(expr)
        
        [tree, expr] = parseNot(expr)
        
        [tree, expr] = parseMult(expr)
        
        [tree, expr] = parseDiv(expr)
        
        [tree, expr] = parsePow(expr)

        % > < <= >=, == !=, && ||
        [tree, expr] = parseRO(expr)

        % =
        [tree, expr] = parseEQ(expr)

    end
end