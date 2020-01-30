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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Fcn_Exp_Parser
    %Fcn_Exp_Parser generates a tree from a mathematical expression in Fcn
    %Block. Fcn Block in Simulink has limited grammar.
    %This function is parsing an expression from left to right. It is not
    %respecting the order of arithmetic operations. 
    %e.g. 3*2 > x*4 => {'Mult', '3', {'>', '2'. {'Mult', 'x', '4'}}}


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