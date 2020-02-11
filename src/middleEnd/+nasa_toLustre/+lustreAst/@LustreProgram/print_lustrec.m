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
function [lus_code, plu_code, ext_lib] = print_lustrec(obj, backend)

    global ADD_KIND2_TIMES_ABSTRACTION ADD_KIND2_DIVIDE_ABSTRACTION;
    ADD_KIND2_TIMES_ABSTRACTION = false;
    ADD_KIND2_DIVIDE_ABSTRACTION = false;
    ext_lib = {};
    lus_header_lines = {};
    lus_lines = {};
    plu_lines = {};
    plu_code = '';
    %opens
    if (LusBackendType.isKIND2(backend) || LusBackendType.isJKIND(backend))
        lus_header_lines = [lus_header_lines; ...
            cellfun(@(x) sprintf('include "%s.lus"\n', x), obj.opens, ...
            'UniformOutput', false)];
    else
        lus_header_lines = [lus_header_lines; ...
            cellfun(@(x) sprintf('#open <%s>\n', x), obj.opens, ...
            'UniformOutput', false)];
    end
    
    %types
    types = cellfun(@(x) sprintf('%s', x.print(backend)), obj.types, ...
        'UniformOutput', false);
    lus_header_lines = MatlabUtils.concat(lus_header_lines, types);
    if LusBackendType.isPRELUDE(backend)
        plu_lines = [plu_lines; types];
    end
    
    % contracts and nodes
    if LusBackendType.isKIND2(backend)
        nodesList = [obj.nodes, obj.contracts];
    else
        nodesList = obj.nodes;
    end
    
    if LusBackendType.isKIND2(backend)
        call_map = containers.Map('KeyType', 'char', ...
            'ValueType', 'any');
        for i=1:numel(nodesList)
            if isempty(nodesList{i})
                continue;
            end
            call_map(nodesList{i}.name) = nodesList{i}.getNodesCalled();
        end
        % Print nodes in order of calling, because KIND2 Contracts
        % need all nodes used in the contract to be defined first.
        alreadyPrinted = {};
        for i=1:numel(nodesList)
            if isempty(nodesList{i})
                continue;
            end
            [lus_lines, alreadyPrinted] = obj.printWithOrder(...
                nodesList, nodesList{i}.name, call_map, alreadyPrinted, lus_lines, backend);
        end
    else
        for i=1:numel(nodesList)
            if isempty(nodesList{i})
                continue;
            end
            if LusBackendType.isPRELUDE(backend) ...
                    && isa( nodesList{i}, 'nasa_toLustre.lustreAst.LustreNode')
                if hasPreludeOperator(nodesList{i})
                    plu_lines{end+1} = sprintf('%s\n', ...
                        nodesList{i}.print(backend, true));
                else
                    
                    lus_lines{end+1} = sprintf('%s\n', ...
                        nodesList{i}.print(LusBackendType.LUSTREC));
                    plu_lines{end+1} = sprintf('%s\n', ...
                        nodesList{i}.print_preludeImportedNode());
                    
                end
            else
                lus_lines{end+1} = sprintf('%s\n', ...
                    nodesList{i}.print(backend));
            end
        end
    end
    if ADD_KIND2_TIMES_ABSTRACTION
        if ~any(MatlabUtils.contains(lus_header_lines, 'kind2_lib.lus'))
            ext_lib{end+1} = 'kind2_lib';
            lus_header_lines = MatlabUtils.concat({sprintf('include "kind2_lib.lus"\n')},...
                lus_header_lines);
        end
    end
    if ADD_KIND2_DIVIDE_ABSTRACTION
        if ~any(MatlabUtils.contains(lus_header_lines, 'kind2_lib.lus'))
            ext_lib{end+1} = 'kind2_lib';
            lus_header_lines = MatlabUtils.concat({sprintf('include "kind2_lib.lus"\n')},...
                lus_header_lines);
        end
    end
    lus_lines = MatlabUtils.concat(lus_header_lines, lus_lines);
    lus_code = MatlabUtils.strjoin(lus_lines, '');
    if LusBackendType.isPRELUDE(backend)
        plu_code = MatlabUtils.strjoin(plu_lines, '');
    end
end

function b = hasPreludeOperator(node)
    if ~isa(node, 'nasa_toLustre.lustreAst.LustreNode')
        b = false;
        return;
    end
    all_body_obj = cellfun(@(x) x.getAllLustreExpr(), node.bodyEqs, 'un',0);
    all_body_obj = MatlabUtils.concat(all_body_obj{:});
    all_objClass = cellfun(@(x) class(x), all_body_obj, 'UniformOutput', false);
    BinaryExprObjects = all_body_obj(strcmp(all_objClass, 'nasa_toLustre.lustreAst.BinaryExpr'));
    operators = cellfun(@(x) x.op, BinaryExprObjects, 'UniformOutput', false);
    b = ismember(nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_DIVIDE, operators) ...
        || ismember(nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_MULTIPLY, operators) ...
        || ismember(nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_OFFSET, operators) ...
        || ismember(nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_FBY, operators);
end

