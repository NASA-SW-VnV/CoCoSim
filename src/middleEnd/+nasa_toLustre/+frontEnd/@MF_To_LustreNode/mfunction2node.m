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
function [main_node, external_nodes ] = ...
        mfunction2node(blkObj, parent,  blk,  xml_trace, lus_backend, ...
        coco_backend, main_sampleTime, varargin)

    
    %
    %
    external_nodes = {};
    main_node = {};
    % get Matlab Function parameters
    
    [blk, Inputs, Outputs] = nasa_toLustre.frontEnd.MF_To_LustreNode.creatInportsOutports(blk);
    try
        % try translate Matlab code to Lustre if failed, it will be set as
        % imported
        [ fun_nodes, failed] = nasa_toLustre.frontEnd.MF_To_LustreNode.getMFunctionCode(blkObj, parent,  blk, Inputs);
        if length(fun_nodes) >= 1
            main_node = fun_nodes{1};
        end
        if length(fun_nodes) > 1
            external_nodes = fun_nodes(2:end);
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'MF_To_LustreNode.mfunction2node', '');
        failed = true;
    end
    if failed
        % create an imported node
        is_main_node = false;
        isEnableORAction = false;
        isEnableAndTrigger = false;
        isContractBlk = false;
        isMatlabFunction = true;
        [node_name, node_inputs, node_outputs,...
            ~, ~] = ...
            nasa_toLustre.utils.SLX2LusUtils.extractNodeHeader(parent, blk, is_main_node,...
            isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction, ...
            main_sampleTime, xml_trace);
        
        comment = nasa_toLustre.lustreAst.LustreComment(...
            sprintf('Original block name: %s', blk.Origin_path), true);
        main_node = nasa_toLustre.lustreAst.LustreNode(...
            comment, ...
            node_name,...
            node_inputs, ...
            node_outputs, ...
            {}, ...
            {}, ...
            {}, ...
            false);
        main_node.setIsImported(true);
        display_msg(sprintf('Matlab Function block "%s" couldn''t be translated to Lustre.\nIt will be abstracted as an imported node.', ...
            HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.WARNING, 'MF_To_LustreNode.mfunction2node', '');
    end
end
