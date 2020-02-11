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
function [code, exp_dt, dim, extra_code] = convFun_To_Lustre(tree, args)

    
    dim = [];
    extra_code = {};
    % Do not forget to update exp_dt in each switch case if needed
    tree_ID = tree.ID;
    
    switch tree_ID
        case {'ceil', 'floor', 'round'}
            expected_param_dt = 'real';
            fun_name = strcat('_', tree_ID);
            lib_name = strcat('LustDTLib_', fun_name);
            args.blkObj.addExternal_libraries(lib_name);
            args.expected_lusDT = expected_param_dt;
            [param, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
            code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr(fun_name, param{i}), ...
                (1:numel(param)), 'UniformOutput', false);
            %ceil(int8(3.4)) returns int8
            %exp_dt = 'real';
            
        case {'int8', 'int16', 'int32', ...
                'uint8', 'uint16', 'uint32', ...
                'double', 'single', 'boolean'}
            
            param = tree.parameters(1);
            if strcmp(param.type, 'constant')
                % cast of constant
                dim = 1;
                v = eval(param.value);
                exp_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(tree_ID);
                code = cell(numel(v), 1);
                for i=1:numel(v)
                    code{i} = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(v(i), exp_dt, tree_ID);
                end
            else
                % cast of expression/variable
                args.expected_lusDT = '';
                [param, param_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
                [external_lib, conv_format] = ...
                    nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(param_dt, tree_ID);
                if ~isempty(conv_format)
                    args.blkObj.addExternal_libraries(external_lib);
                    code = arrayfun(@(i) ...
                        nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format, param{i}), ...
                        (1:numel(param)), 'UniformOutput', false);
                    exp_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(tree_ID);
                else
                    % no casting needed
                    code = param;
                    exp_dt = param_dt;
                end
            end
        otherwise
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" is not handled in Block %s',...
                tree.ID, args.blk.Origin_path);
            throw(ME);
    end
end

