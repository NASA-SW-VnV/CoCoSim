%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
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
function extNode = get_Lookup_nD_Dynamic_wrapper(blkParams,inputs,...
    preLookUpExtNode,interpolationExtNode)

%    % Lookup_nD
         
    % node header
    wrapper_header.NodeName = sprintf('%s_Lookup_wrapper_node',...
        blkParams.blk_name);
    % node header inputs
    wrapper_header.inputs = preLookUpExtNode.inputs;
    if nasa_toLustre.utils.LookupType.isLookupDynamic(blkParams.lookupTableType)
        numTableData = numel(inputs{3});
        for i=1:numTableData
            wrapper_header.inputs{end+1} = interpolationExtNode.inputs{...
                numel(interpolationExtNode.inputs)-numTableData+i};
        end
    end
    % node outputs, only y_out
    wrapper_header.output = interpolationExtNode.outputs; 
    
    % Declare variables for Pre look up outputs
    vars = preLookUpExtNode.outputs;    
    
    % call prelookup
    pre_outputs = ...
        cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.id),...
        preLookUpExtNode.outputs,'UniformOutput',false);
    pre_inputs = ...
        cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.id),...
        preLookUpExtNode.inputs,'UniformOutput',false);
    body{1} = ...
        nasa_toLustre.lustreAst.LustreEq(pre_outputs, ...
        nasa_toLustre.lustreAst.NodeCallExpr(...
        preLookUpExtNode.name, pre_inputs));
    % call interpolation_using_prelookup
    interp_outputs = ...
        cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.id),...
        interpolationExtNode.outputs,'UniformOutput',false);
    interp_inputs = ...
        cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.id),...
        interpolationExtNode.inputs,'UniformOutput',false);    
%     if isempty(output_conv_format)
    node_call_expr = nasa_toLustre.lustreAst.NodeCallExpr(...
        interpolationExtNode.name, interp_inputs);
%     else
%         node_call_expr = ...
%             nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
%             output_conv_format, nasa_toLustre.lustreAst.NodeCallExpr(...
%             interpolationExtNode.name, interp_inputs));
%     end
    body{2} = ...
        nasa_toLustre.lustreAst.LustreEq(interp_outputs, node_call_expr);

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(wrapper_header.NodeName)
    extNode.setInputs(wrapper_header.inputs);
    extNode.setOutputs( wrapper_header.output);
    extNode.setLocalVars(vars);
    extNode.setBodyEqs(body);

end

