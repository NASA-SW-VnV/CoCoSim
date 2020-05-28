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
classdef MExpToLusDT
    %MEXPTOLUSDT returns Lustre DataType of an expression

        
    properties
    end
    
    methods(Static)
        % sort by alphabetic order
        [lusDT, slxDT] = assignment_DT(tree, args)
        [lusDT, slxDT] = binaryExpression_DT(tree, args)
        [lusDT, slxDT] = colonExpression_DT(tree, args)
        [lusDT, slxDT] = constant_DT(tree, args)
        [lusDT, slxDT] = end_DT(tree, args)
        [lusDT, slxDT] = expression_DT(tree, args)
        [lusDT, slxDT] = fun_indexing_DT(tree, args)
        [lusDT, slxDT] = ID_DT(tree, args)
        [lusDT, slxDT] = ignore_value_DT(varargin)
        [lusDT, slxDT] = matrix_DT(tree, args)
        [lusDT, slxDT] = parenthesedExpression_DT(tree, args)
        [lusDT, slxDT] = struct_indexing_DT(tree, args)
        [lusDT, slxDT] = transpose_DT(tree, args)
        [lusDT, slxDT] = unaryExpression_DT(tree, args)
        [lusDT, slxDT] = while_block_DT(tree, args)
    end
    
    methods(Static)
        %Utils
        function [lusDT, slxDT] = getVarDT(data_map, var_name)
            if ~isKey(data_map, var_name)
                lusDT = '';
                slxDT = '';
                return;
            end
            if isfield(data_map(var_name), 'LusDatatype')
                lusDT = data_map(var_name).LusDatatype;
                slxDT = data_map(var_name).CompiledType;
            elseif ischar(data_map(var_name))
                lusDT = data_map(var_name);
                slxDT = LusValidateUtils.get_slx_dt(lusDT);
            else
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Variable data_map is not well defined');
                throw(ME);
            end
        end
        
        function [new_code, new_output_dt] = convertDT(obj, code, input_dt, output_dt)
            new_code = code;
            new_output_dt = output_dt;
            if isempty(code) ...
                    || isempty(input_dt) ...
                    || isempty(output_dt) 
                return;
            end
            if ischar(input_dt)
                input_dt = {input_dt};
            end
            if ischar(output_dt)
                output_dt = {output_dt};
            end
            if  length(code) < length(input_dt)
                return;
            end
            try
                [code, input_dt, failed] = nasa_toLustre.utils.MExpToLusAST.inlineOperands(code, input_dt);
                if failed
                    return;
                end
                [output_dt, input_dt, failed] = nasa_toLustre.utils.MExpToLusAST.inlineOperands(output_dt, input_dt);
                if failed
                    return;
                end
                new_code =  cell(1, length(code));
                new_output_dt = cell(1, length(code));
                for i=1:length(new_code)
                    if strcmp(input_dt{i}, output_dt{i})
                        new_code{i} = code{i};
                        new_output_dt = output_dt{i};
                        continue;
                    end
                    if strcmp(output_dt{i}, 'int') && (isa(code{i}, 'nasa_toLustre.lustreAst.RealExpr') ...
                            || isa(code{i}, 'nasa_toLustre.lustreAst.BoolExpr'))
                        new_code{i} = nasa_toLustre.lustreAst.IntExpr(int32(code{i}.value));
                        continue
                    end
                    if strcmp(output_dt{i}, 'real') && (isa(code{i}, 'nasa_toLustre.lustreAst.IntExpr') ...
                            || isa(code{i}, 'nasa_toLustre.lustreAst.BoolExpr'))
                        new_code{i} = nasa_toLustre.lustreAst.RealExpr(code{i}.value);
                        continue
                    end
                    if strcmp(output_dt{i}, 'bool') && (isa(code{i}, 'nasa_toLustre.lustreAst.RealExpr') ...
                            || isa(code{i}, 'nasa_toLustre.lustreAst.IntExpr'))
                        new_code{i} = nasa_toLustre.lustreAst.BoolExpr(boolean(code{i}.value));
                        continue
                    end
                    conv = strcat(input_dt{i}, '_to_', output_dt{i});
                    obj.addExternal_libraries(strcat('LustDTLib_', conv));
                    new_code{i} = nasa_toLustre.lustreAst.NodeCallExpr(conv, code(i));
                    new_output_dt = output_dt{i};
                end
            catch me
                display_msg(sprintf('I could not cast expression: %s\n', code{1}.print(coco_nasa_utils.LusBackendType.LUSTREC)), ...
                    MsgType.DEBUG, 'MExpToLusDT.convertDT', '')
                display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusDT.convertDT', '');
                % ignore type casting
            end
           
        end
        
        function [lusDT, slxDT] = upperDT(left_lusDT, right_lusDT, left_slxDT, right_slxDT)
            if nargin < 3 
                left_slxDT = '';
            end
            if nargin < 4 
                right_slxDT = '';
            end
            if isempty(left_lusDT) && isempty(right_lusDT)
                lusDT = '';
                slxDT = '';
                return;
            end
            if isempty(left_lusDT)
                lusDT = right_lusDT;
                slxDT = right_slxDT;
                return;
            end
            if isempty(right_lusDT)
                lusDT = left_lusDT;
                slxDT = left_slxDT;
                return;
            end
            
            if strcmp(left_lusDT, 'real') || strcmp(right_lusDT, 'real')
                lusDT = 'real';
                if strcmp(left_slxDT, 'double') || strcmp(right_slxDT, 'double')
                    slxDT = 'double';
                else
                    slxDT = left_slxDT;
                end
            elseif strcmp(left_lusDT, 'int') || strcmp(right_lusDT, 'int')
                lusDT = 'int';
                if coco_nasa_utils.MatlabUtils.contains(left_slxDT, 'int') ...
                        && coco_nasa_utils.MatlabUtils.contains(right_slxDT, 'int')
                    d1 = str2double(regexprep(left_slxDT, '[a-zA-Z]+', ''));
                    d2 = str2double(regexprep(right_slxDT, '[a-zA-Z]+', ''));
                    if d1 > d2
                        slxDT = left_slxDT;
                    else
                        slxDT = right_slxDT;
                    end
                else
                    if coco_nasa_utils.MatlabUtils.contains(left_slxDT, 'int')
                        slxDT = left_slxDT;
                    else
                        slxDT = right_slxDT;
                    end
                end
            elseif strcmp(left_lusDT, 'bool') && strcmp(right_lusDT, 'bool')
                lusDT = 'bool';
                slxDT = 'boolean';
            else
                lusDT = '';
                slxDT = '';
                return;
            end
        end
        
    end
end

