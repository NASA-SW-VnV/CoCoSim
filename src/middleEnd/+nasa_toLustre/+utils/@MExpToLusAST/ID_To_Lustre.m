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
function [code, dt, dim, extra_code] = ID_To_Lustre(tree, args)

    
    dim = [];
    extra_code = {};
    if ischar(tree)
        id = tree;
    else
        id = tree.name;
    end
    dt = nasa_toLustre.utils.MExpToLusDT.ID_DT(tree, args);
    if strcmp(id, 'true') || strcmp(id, 'false')
        code{1} = nasa_toLustre.lustreAst.BoolExpr(id);
        dim = [1 1];
    elseif args.isSimulink && strcmp(id, 'u')
        %the case of u with no index in IF/Fcn/SwitchCase blocks
        code{1} = args.inputs{1}{1};
        dim = [1 1];
    elseif args.isSimulink && ~isempty(regexp(id, 'u\d+', 'match'))
        %the case of u1, u2 in IF/Fcn/SwitchCase blocks
        input_idx = regexp(id, 'u(\d+)', 'tokens', 'once');
        code{1} = args.inputs{str2double(input_idx)}{1};
        dim = [1 1];
    elseif isKey(args.data_map, id)
        d = args.data_map(id);
        if isfield(d, 'CompiledSize')
            dim = str2num(d.CompiledSize);
        elseif isfield(d, 'ArraySize')
            dim = str2num(d.ArraySize);
        else
            dim = [];
        end
        if args.isStateFlow || args.isMatlabFun
            names = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataName(d);
            code = cell(numel(names), 1);
            for i=1:numel(names)
                code{i} = nasa_toLustre.lustreAst.VarIdExpr(names{i});
            end
        else
            code{1} = nasa_toLustre.lustreAst.VarIdExpr(id);
        end
    else
        try
            %check for variables in workspace
            [value, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(args.parent, args.blk, id);
            if status
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Not found Variable "%s" in block "%s"', ...
                    id, args.blk.Origin_path);
                throw(ME);
            end
            dt = args.expected_lusDT;
            dim = size(value);
            code = cell(numel(value), 1);
            for i=1:numel(value)
                if strcmp(args.expected_lusDT, 'bool')
                    code{i} = nasa_toLustre.lustreAst.BoolExpr(value(i));
                elseif strcmp(args.expected_lusDT, 'int')
                    code{i} = nasa_toLustre.lustreAst.IntExpr(value(i));
                else
                    code{i} = nasa_toLustre.lustreAst.RealExpr(value(i));
                    dt = 'real';
                end
            end
        catch me
            %code = nasa_toLustre.lustreAst.VarIdExpr(var_name);
            ME = MException('COCOSIM:TREE2CODE', ...
                'Not found Variable "%s" in block "%s"', ...
                id, args.blk.Origin_path);
            throw(ME);
        end
    end
end
