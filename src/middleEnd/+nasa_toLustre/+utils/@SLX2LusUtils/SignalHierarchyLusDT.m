
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
function [lus_dt] = SignalHierarchyLusDT(blk, SignalHierarchy)
    %isBus = false;
    lus_dt = {};
    try
        if ~isfield(SignalHierarchy, 'SignalName')
            display_msg(sprintf('Bock %s has an auto dataType and is not supported',...
            blk.Origin_path), MsgType.ERROR, '', '');
            lus_dt = 'real';
            return;
        end
        SignalName = SignalHierarchy.SignalName;
        if isempty(SignalHierarchy.SignalName) ...
                || coco_nasa_utils.SLXUtils.isSimulinkBus(SignalHierarchy.BusObject)
            SignalName = SignalHierarchy.BusObject;
        end
        if isempty(SignalName)
            if  ~isfield(SignalHierarchy, 'Children') ...
                    || isempty(SignalHierarchy.Children)
                lus_dt = 'real';
                display_msg(sprintf('Bock %s has an auto dataType and is not supported',...
                    blk.Origin_path), MsgType.ERROR, '', '');
                return;
            else
                for i=1:numel(SignalHierarchy.Children)
                    [lus_dt_i] = ...
                        nasa_toLustre.utils.SLX2LusUtils.SignalHierarchyLusDT(blk, SignalHierarchy.Children(i));
                    if iscell(lus_dt_i)
                        lus_dt = [lus_dt, lus_dt_i];
                    else
                        lus_dt{end+1} = lus_dt_i;
                    end
                end
                return;
            end
        end
        isBus = coco_nasa_utils.SLXUtils.isSimulinkBus(SignalName);
        if isBus
            lus_dt =...
                nasa_toLustre.utils.SLX2LusUtils.getLustreTypesFromBusObject(SignalName);
        else
            p = find_system(bdroot(blk.Origin_path),...
                'FindAll', 'on', ...
                'Type', 'port',...
                'PortType', 'outport', ...
                'SignalNameFromLabel', SignalName );
            BusCreatorFound = false;
            for i=1:numel(p)
                p_parent=  get_param(p(i), 'Parent');
                p_parentObj = get_param(p_parent, 'Object');
                if strcmp(p_parentObj.BlockType, 'BusCreator')
                    BusCreatorFound = true;
                    break;
                end
            end
            if BusCreatorFound
                global model_struct
                parent = get_struct(model_struct, ...
                    get_param(p_parentObj.Parent, 'Handle'));
                srcBk = get_struct(model_struct, p_parentObj.Handle);
                lus_dt = nasa_toLustre.utils.SLX2LusUtils.getBusCreatorLusDT(...
                    parent, ...
                    srcBk, ...
                    get_param(p(i), 'PortNumber'));
            elseif numel(p) >= 1
                compiledDT = coco_nasa_utils.SLXUtils.getCompiledParam(p(1), 'CompiledPortDataType');
                [lus_dt, ~, ~, ~] = ...
                    nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(compiledDT);
                CompiledPortWidth = coco_nasa_utils.SLXUtils.getCompiledParam(p(1), 'CompiledPortWidth');
                if iscell(lus_dt) && numel(lus_dt) < CompiledPortWidth
                    lus_dt = arrayfun(@(x) lus_dt{1}, (1:CompiledPortWidth), ...
                        'UniformOutput', 0);
                else
                    lus_dt = arrayfun(@(x) lus_dt, (1:CompiledPortWidth), ...
                        'UniformOutput', 0);
                end
            else
                lus_dt = 'real';
            end
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'getBlockOutputsNames', '');
        lus_dt = 'real';
    end
end
