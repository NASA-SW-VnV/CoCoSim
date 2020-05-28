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
function [body, variables, external_nodes, external_libraries, abstractedBlocks] =...
        write_body(subsys, main_sampleTime, lus_backend, coco_backend, xml_trace)
    %% Go over SS Content
    global CoCoSimPreferences
    
    if isempty(CoCoSimPreferences)
        CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    end
         
    %
    %
    variables = {};
    body = {};
    external_nodes = {};
    external_libraries = {};
    abstractedBlocks = {};

    fields = fieldnames(subsys.Content);
    fields = ...
        fields(cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));
    if numel(fields)>=1
        xml_trace.create_Variables_Element();
    end
    for i=1:numel(fields)
        blk = subsys.Content.(fields{i});
        [b, status, type, masktype, sfblockType, ~] = nasa_toLustre.utils.getWriteType(blk, lus_backend);
        if status
            continue;
        end
        try
            b.write_code(subsys, blk, xml_trace, lus_backend, coco_backend, main_sampleTime);
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'write_body', '');
            msg = sprintf('Translation to Lustre of block %s has failed.', HtmlItem.addOpenCmd(blk.Origin_path));
            if coco_nasa_utils.LusBackendType.isKIND2(CoCoSimPreferences.lustreBackend) ...
                    && CoCoSimPreferences.abstract_unsupported_blocks
                try
                    display_msg(sprintf('%s. It will be abstracted',msg),...
                        MsgType.WARNING, 'write_body', '');
                    fun_name = 'nasa_toLustre.blocks.AbstractBlock_To_Lustre';
                    h = str2func(fun_name);
                    b = h();
                    b.write_code(subsys, blk, xml_trace, lus_backend, coco_backend, main_sampleTime);
                catch
                    display_msg(msg, MsgType.ERROR, 'write_body', '');
                end
            else
                display_msg(msg, MsgType.ERROR, 'write_body', '');
            end
        end
        code = b.getCode();
        if iscell(code)
            body = [body, code];
        else
            body{end+1} = code;
        end
        variables = [variables, b.getVariables()];
        external_nodes = [external_nodes, b.getExternalNodes()];
        external_libraries = [external_libraries, b.getExternalLibraries()];
        if b.blkIsAbstracted
            if ~isempty(sfblockType) && ~strcmp(sfblockType, 'NONE')
                blkType = sfblockType;
            elseif ~isempty(masktype)
                blkType = masktype;
            else
                blkType = type;
            end
            msg = sprintf('Block "%s" with Type "%s".', ...
                HtmlItem.addOpenCmd(blk.Origin_path), blkType);
            abstractedBlocks{end+1} = msg;
        end
    end
end
