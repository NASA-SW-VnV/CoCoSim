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
function htmlItemMsg = modelCompatibilityCheck(model_name, main_sampleTime)
    htmlItemMsg = '';
    subtitles = {};
    try
        all_blocks = find_system(model_name,...
            'Regexp', 'on',...
            'LookUnderMasks', 'all', 'BlockType','\w');
        portHandles = get_param(all_blocks, 'portHandles');
        outPortHandle = cellfun(@(x) x.Outport, portHandles, 'un', 0);
        outPortHandle = outPortHandle(cellfun(@(x) ~isempty(x), outPortHandle));
        outPortHandleVector = coco_nasa_utils.MatlabUtils.concat(outPortHandle{:});
        code_on=sprintf('%s([], [], [], ''compile'')', model_name);
        evalin('base',code_on);
        varSize = arrayfun(@(x) get_param(x, 'CompiledPortDimensionsMode'),...
            outPortHandleVector,  'un', 0);
        compiledPortDT = arrayfun(@(x) get_param(x, 'CompiledPortDataType'),...
            outPortHandleVector,  'un', 0);
        code_off=sprintf('%s([], [], [], ''term'')', model_name);
        evalin('base',code_off);
        
        % check for variable size signals
        varSize_idx = find(cellfun(@(x) sum(x), varSize), 1);
        if ~isempty(varSize_idx)
            blk_name = get_param(outPortHandleVector(varSize_idx), 'Parent');
            msg = sprintf('Your model has signals with variable size (e.g. Block %s output signal). CoCoSim does not support models with variable size signals.',...
                HtmlItem.addOpenCmd(blk_name));
            subtitles{end+1} = HtmlItem(msg, {}, 'black');
        end
        
        % check for fixed data type signals
        fixdt_idx = find(...
            cellfun(@(x) ...
            coco_nasa_utils.MatlabUtils.startsWith(x, 'sfix') ...
            || coco_nasa_utils.MatlabUtils.startsWith(x, 'ufix') ...
            || coco_nasa_utils.MatlabUtils.startsWith(x, 'fltu') ...
            || coco_nasa_utils.MatlabUtils.startsWith(x, 'flts'), compiledPortDT), 1);
        if ~isempty(fixdt_idx)
            blk_name = get_param(outPortHandleVector(fixdt_idx), 'Parent');
            msg = sprintf('Your model has signals with Fixed-Point Data (e.g. Block %s output signal). CoCoSim does not support models with Fixed-Point Data Type. Please set block output datatype parameter to one of the following: Bus object, Enumeration, double, single, boolean, int8, uint8, int16, uint16, int32, uint32.',...
                HtmlItem.addOpenCmd(blk_name));
            subtitles{end+1} = HtmlItem(msg, {}, 'black');
        end
        
        % Check sample time offset is null
        if numel(main_sampleTime) >= 2 && main_sampleTime(2) ~= 0
            msg = sprintf('Your model is running with a CompiledSampleTime [%d, %d], offset time not null is not supported in the root level.',...
                main_sampleTime(1), main_sampleTime(2));
            subtitles{end+1} = HtmlItem(msg, {}, 'black');
        end
        
        if ~isempty(subtitles)
            htmlItemMsg = HtmlItem('Model', subtitles, 'blue');
        end
    catch
    end
end

