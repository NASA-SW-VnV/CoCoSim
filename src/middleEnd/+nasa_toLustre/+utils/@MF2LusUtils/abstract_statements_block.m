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
function [while_node] = abstract_statements_block(tree, args, type)
    %ABSTRACT_STATEMENTS_BLOCK abstract WHILE, FOR and SWITCH blocks

    persistent counter;
    if isempty(counter)
        counter = 0;
    end
    while_node = {};
    IDs = modifiedVars(tree);
    if isempty(IDs)
        return;
    end
    data_set = args.data_map.values();
    data_set = data_set(cellfun(@(x) ismember(x.Name, IDs), data_set));
    if isempty(data_set)
        return;
    end
    node_inputs{1} = nasa_toLustre.lustreAst.LustreVar(...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(),...
        'bool');
    node_outputs = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataVars(data_set);
    counter = counter + 1;
    node_name = sprintf('%s_abstract_%s_%d', ...
        nasa_toLustre.utils.SLX2LusUtils.node_name_format(args.blk), type, ...
        counter);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('%s code is abstracted inside Matlab Function block: %s\n The code is the following :\n%s',...
        type, args.blk.Origin_path, tree.text), true);
    while_node = nasa_toLustre.lustreAst.LustreNode(...
        comment, ...
        node_name,...
        node_inputs, ...
        node_outputs, ...
        {}, ...
        {}, ...
        {}, ...
        false, true);
end

function IDs = modifiedVars(tree)
    IDs = {};
    if isfield(tree, 'statements')
        tree = tree.statements;
    end
    if isstruct(tree)
        tree_statements = arrayfun(@(x) x, tree, 'UniformOutput', 0);
    else
        tree_statements = tree;
    end
    for i=1:length(tree_statements)
        if strcmp(tree_statements{i}.type, 'assignment')
            IDs = coco_nasa_utils.MatlabUtils.concat(IDs, ...
                nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(tree_statements{i}));
        elseif isfield(tree_statements{i}, 'statements')
            IDs = coco_nasa_utils.MatlabUtils.concat(IDs, modifiedVars(tree_statements{i}));
        end
    end
end