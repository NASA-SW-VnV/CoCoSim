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
function [code, exp_dt, dim, extra_code] = constant_To_Lustre(tree, args)

    code = {};
    exp_dt = args.expected_lusDT;
    dim = [1 1];
    extra_code = {};
    if ~strcmp(tree.dataType, 'Integer') && ~strcmp(tree.dataType, 'Float')
        % String | function_handle
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" is not handled in Block %s',...
            tree.text, args.blk.Origin_path);
        throw(ME);
    end
    
    v = tree.value;
    
    if strcmp(args.expected_lusDT, 'real')
        code{1} = nasa_toLustre.lustreAst.RealExpr(str2double(v));
    elseif strcmp(args.expected_lusDT, 'bool')
        code{1} = nasa_toLustre.lustreAst.BoolExpr(str2double(v));
    elseif strcmp(args.expected_lusDT, 'int')
        %tree might be 1 or 3e5
        code{1} = nasa_toLustre.lustreAst.IntExpr(str2double(v));
    elseif strcmp(tree.dataType, 'Integer')
        code{1} = nasa_toLustre.lustreAst.IntExpr(str2double(v));
        exp_dt = 'int';
    elseif strcmp(tree.dataType, 'Float')
        code{1} = nasa_toLustre.lustreAst.RealExpr(str2double(v));
        exp_dt = 'real';
    else
        % String | function_handle
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" is not handled in Block %s',...
            tree.text, args.blk.Origin_path);
        throw(ME);
        
    end
end
