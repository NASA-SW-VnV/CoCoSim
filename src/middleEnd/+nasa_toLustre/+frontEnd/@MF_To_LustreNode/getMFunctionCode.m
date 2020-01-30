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
function [external_nodes, failed] = getMFunctionCode(blkObj, parent,  blk, Inputs)
    %GETMFUNCTIONCODE

    
    %
    %
    global SF_MF_FUNCTIONS_MAP MFUNCTION_EXTERNAL_NODES
    % reset MFUNCTION_EXTERNAL_NODES
    MFUNCTION_EXTERNAL_NODES = {};
    external_nodes ={};
    % get all user functions needed in one script
    [script, failed] = nasa_toLustre.frontEnd.MF_To_LustreNode.getAllRequiredFunctionsInOneScript(blk );
    if failed, return; end
    % get all functions IR
    [funcList, failed] = nasa_toLustre.frontEnd.MF_To_LustreNode.getFunctionList(blk, script);
    if failed, return; end
    
    if isempty(funcList)
        display_msg(sprintf('Parser failed for Matlab function in block %s. No function has been found.', ...
            HtmlItem.addOpenCmd(blk.Origin_path)),...
            MsgType.WARNING, 'getMFunctionCode', '');
        failed = 1;
        return;
    end
    
    % creat DATA_MAP
    [fun_data_map, failed] = nasa_toLustre.frontEnd.MF_To_LustreNode.getFuncsDataMap(parent, blk, script, ...
        funcList, Inputs);
    if failed, return; end
    
    % Get all functions information before generating code
    func_names = cellfun(@(func) func.name, funcList, 'UniformOutput', 0);
    usedFunc = {};
    func_nodes = {};
    for i=1:length(func_names)
        fstruct = funcList{i};
        if isKey(fun_data_map, fstruct.name)
            func_nodes{end+1} = nasa_toLustre.frontEnd.MF_To_LustreNode.getFunHeader(...
                fstruct, blk, fun_data_map(fstruct.name));
            usedFunc{end+1} = fstruct;
        end
    end
    usedFunctionsNames = cellfun(@(func) func.name, usedFunc, 'UniformOutput', 0);
    SF_MF_FUNCTIONS_MAP = containers.Map(usedFunctionsNames, func_nodes);
    
    %generate code
    [external_nodes, failed] = cellfun(@(func) ...
        nasa_toLustre.frontEnd.MF_To_LustreNode.getFuncCode(func, fun_data_map(func.name), blkObj, parent, blk), ...
        usedFunc, 'UniformOutput', 0);
    failed = all([failed{:}]);
    if ~isempty(MFUNCTION_EXTERNAL_NODES)
        external_nodes = MatlabUtils.concat(external_nodes, MFUNCTION_EXTERNAL_NODES);
    end
end


