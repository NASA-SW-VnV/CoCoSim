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
function lookupWrapperExtNode = create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)

    global CoCoSimPreferences
    %    % Lookup_nD
    
    [interpolationExtNode, new_outputs] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_interp_using_pre_node(obj,...
        blkParams,inputs);
    
    [preLookUpExtNode, new_inputs] =  ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_pre_lookup_node(...
        lus_backend,blkParams,inputs);
    
    lookupWrapperExtNode = obj.get_wrapper_node(blk,blkParams,inputs,...
        preLookUpExtNode,interpolationExtNode);
    if isfield(CoCoSimPreferences, 'abstract_lookuptables') ...
            && CoCoSimPreferences.abstract_lookuptables...
            && coco_nasa_utils.LusBackendType.isKIND2(lus_backend) ...
            && blkParams.NumberOfTableDimensions <= 3
        
        %Using abstractions to improve verification results
        contractBody = nasa_toLustre.blocks.Lookup_nD_To_Lustre.getContractBody(...
            blkParams, new_inputs, new_outputs);
        contract = nasa_toLustre.lustreAst.LustreContract();
        contract.setBodyEqs(contractBody);
        lookupWrapperExtNode.setLocalContract(contract);
        lookupWrapperExtNode.setIsImported(true);
        obj.addExtenal_node(lookupWrapperExtNode);
    else
        obj.addExtenal_node(interpolationExtNode);
        obj.addExtenal_node(preLookUpExtNode);
        obj.addExtenal_node(lookupWrapperExtNode);
    end
    
    
    
    
end

