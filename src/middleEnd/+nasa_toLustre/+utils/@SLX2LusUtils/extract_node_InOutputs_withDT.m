
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [names, names_withNoDT] = extract_node_InOutputs_withDT(subsys, type, xml_trace, main_sampleTime)
    %get all blocks names
    fields = fieldnames(subsys.Content);

    % remove blocks without BlockType (e.g annotations)
    fields = ...
        fields(...
        cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));

    % get only blocks with BlockType=type
    Portsfields = ...
        fields(...
        cellfun(@(x) strcmp(subsys.Content.(x).BlockType,type), fields));

    isInsideContract = nasa_toLustre.utils.SLX2LusUtils.isContractBlk(subsys);
    % sort the blocks by order of their ports
    ports = cellfun(@(x) str2num(subsys.Content.(x).Port), Portsfields);
    [~, I] = sort(ports);
    Portsfields = Portsfields(I);
    names = {};
    names_withNoDT = {};
    for i=1:numel(Portsfields)
        block = subsys.Content.(Portsfields{i});
        [names_withNoDT_i, names_i] = ...
            nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
            subsys, block, [], [], main_sampleTime);
        names = [names, names_i];
        names_withNoDT = [names_withNoDT, names_withNoDT_i];
        % traceability
        width = numel(names_withNoDT_i);
        IsNotInSimulink = false;
        for index=1:numel(names_withNoDT_i)
            xml_trace.add_InputOutputVar( type, names_withNoDT_i{index}.getId(), ...
                block.Origin_path, 1, width, index, isInsideContract, IsNotInSimulink);
        end
    end
    
    if strcmp(type, 'Inport')
        % add enable port to the node inputs, if ShowOutputPort is
        % on
        enablePortsFields = fields(...
            cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'EnablePort'), fields));
        if ~isempty(enablePortsFields) ...
                && strcmp(subsys.Content.(enablePortsFields{1}).ShowOutputPort, 'on')
            [names_withNoDT_i, names_i] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
                subsys, subsys.Content.(enablePortsFields{1}), [], [], main_sampleTime);
            names = [names, names_i];
            names_withNoDT = [names_withNoDT, names_withNoDT_i];
            % traceability
            width = numel(names_withNoDT_i);
            IsNotInSimulink = false;
            block = subsys.Content.(enablePortsFields{1});
            for index=1:numel(names_withNoDT_i)
                xml_trace.add_InputOutputVar( type, names_withNoDT_i{index}.getId(), ...
                    block.Origin_path, 1, width, index, isInsideContract, IsNotInSimulink);
            end
        end
        % add trigger port to the node inputs, if ShowOutputPort is
        % on
        triggerPortsFields = fields(...
            cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'TriggerPort'), fields));
        if ~isempty(triggerPortsFields) ...
                && strcmp(subsys.Content.(triggerPortsFields{1}).ShowOutputPort, 'on')
            [names_withNoDT_i, names_i] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
                subsys, subsys.Content.(triggerPortsFields{1}), [], [], main_sampleTime);
            names = [names, names_i];
            names_withNoDT = [names_withNoDT, names_withNoDT_i];
            % traceability
            width = numel(names_withNoDT_i);
            IsNotInSimulink = false;
            block = subsys.Content.(triggerPortsFields{1});
            for index=1:numel(names_withNoDT_i)
                xml_trace.add_InputOutputVar( type, names_withNoDT_i{index}.getId(), ...
                    block.Origin_path, 1, width, index, isInsideContract, IsNotInSimulink);
            end
        end
    end
end
