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
function [lusDT, slxDT] = fun_indexing_DT(tree, args)

    
    
    tree_ID = tree.ID;
    switch tree_ID
        case {'abs', 'sgn'}
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.expression_DT(...
                tree.parameters(1), args);
        case 'rem'
            [lusDT1, slxDT1] = nasa_toLustre.utils.MExpToLusDT.expression_DT(...
                tree.parameters(1), args);
            [lusDT2, slxDT2] = nasa_toLustre.utils.MExpToLusDT.expression_DT(...
                tree.parameters(2), args);
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.upperDT(...
                lusDT1, lusDT2, slxDT1, slxDT2);
        case {'sqrt', 'exp', 'log', 'log10',...
                'sin','cos','tan',...
                'asin','acos','atan','atan2', 'power', ...
                'sinh','cosh', ...
                'ceil', 'floor', 'hypot'}
            lusDT = 'real';
            slxDT = 'double';
        case {'all', 'any'}
            lusDT = 'bool';
            slxDT = 'boolean';
        otherwise
            [lusDT, slxDT] = simulinkStateflow_Fun_Indexing_DT(tree, args);
    end
end

function [lusDT, slxDT] = simulinkStateflow_Fun_Indexing_DT(tree, args)
    global SF_MF_FUNCTIONS_MAP;% SF_STATES_NODESAST_MAP;
    
    data_map = args.data_map;
    inputs = args.inputs;
    isSimulink = args.isSimulink;
    isStateFlow = args.isStateFlow;
    isMatlabFun = args.isMatlabFun;
    lusDT = '';
    slxDT = '';
    if (isStateFlow || isMatlabFun) && data_map.isKey(tree.ID)
        % A variable in Stateflow
        [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(...
            data_map, tree.ID);
    elseif (isStateFlow || isMatlabFun)  && SF_MF_FUNCTIONS_MAP.isKey(tree.ID)
        % Graphical function in Stateflow
        nodeAst = SF_MF_FUNCTIONS_MAP(tree.ID);
        outputs = nodeAst.getOutputs();
        lusDT =  cell(numel(outputs), 1);
        for i=1:numel(outputs)
            d = outputs{i};
            lusDT{i} = d.getDT();
        end
        slxDT = LusValidateUtils.get_slx_dt(lusDT);
    elseif isSimulink && strcmp(tree.ID, 'u')
        %"u" refers to an input in IF, Switch and Fcn
        %blocks
        if strcmp(tree.parameters(1).type, 'constant')
            %the case of u(1), u(2) ...
            input_idx = str2double(tree.parameters(1).value);
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{1}{input_idx}.getId());
        else
            % we assume "u" is a vector of the same dataType. Which is the
            % case for Fcn/IF/Switch case blocks where isSimulink=true
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{1}{1}.getId());
        end
        
    elseif isSimulink &&  ~isempty(regexp(tree.ID, 'u\d+', 'match'))
        % case of u1, u2 ...
        input_number = str2double(regexp(tree.ID, 'u(\d+)', 'tokens', 'once'));
        if strcmp(tree.parameters(1).type, 'constant')
            arrayIndex = str2double(tree.parameters(1).value);
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{input_number}{arrayIndex}.getId());
        else
            % we assume "u" is a vector of the same dataType. Which is the
            % case for Fcn/IF/Switch case blocks where isSimulink=true
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{input_number}{1}.getId());
        end
    end
end
