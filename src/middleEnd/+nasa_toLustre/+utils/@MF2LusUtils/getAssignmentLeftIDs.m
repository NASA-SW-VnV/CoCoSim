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
function [IDs] = getAssignmentLeftIDs(tree)
    IDs = {};
    if isempty(tree)
        return;
    end
    if iscell(tree) && numel(tree) == 1
        tree = tree{1};
    end
    if ~isfield(tree, 'type')
        if isfield(tree, 'text')
            ME = MException('COCOSIM:TREE2CODE', ...
                'getAssignmentLeftIDs Failed: Matlab AST of expression "%s" has no attribute type.',...
                tree.text);
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'getAssignmentLeftIDs Failed: Matlab AST has no attribute type.');
        end
        throw(ME);
    end
    if strcmp(tree.type, 'assignment')
        tree = tree.leftExp;
    end
    tree_type = tree.type;
    %%
    switch tree_type
        case 'struct_indexing'
            IDs = nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(tree.leftExp);
            
        case 'fun_indexing'
            if ischar(tree.ID)
                IDs{1} = tree.ID;
            else
                IDs = nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(tree.ID);
            end
            
        case 'cell_indexing'
            IDs{1} = tree.ID;
            
        case 'parenthesedExpression'
            IDs = nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(tree.expression);
            
        case 'ID'
            IDs{1} = tree.name;
            
        case 'matrix'
            % matrix should have one row if it is on the left of an assignment
            if isstruct(tree.rows)
                rows = arrayfun(@(x) x, tree.rows, 'UniformOutput', false);
            else
                rows = tree.rows;
            end
            
            nb_rows = numel(rows);
            if nb_rows > 1
                ME = MException('COCOSIM:TREE2CODE', ...
                    'getAssignmentLeftIDs Failed: Unexpected expression "%s" on the left side of an assignment.',...
                    tree.text);
                throw(ME);
            end
            nb_columns = numel(rows{1});
            for j=1:nb_columns
                    v = rows{1}(j);
                    IDs = coco_nasa_utils.MatlabUtils.concat(IDs, ...
                        nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(v));
            end
    end
end

