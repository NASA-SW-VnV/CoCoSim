%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function htmlItemMsg = modelCompatibilityCheck(model_name, main_sampleTime)
    htmlItemMsg = '';
    subtitles = {};
    try
        all_blocks = find_system(model_name,...
            'Regexp', 'on',...
            'LookUnderMasks', 'all', 'BlockType','\w');
        portHandles = get_param(all_blocks, 'portHandles');
        outPortHandle = cellfun(@(x) x.Outport, portHandles, 'un', 0);
        outPortHandle = outPortHandle(cellfun(@(x) ~isempty(x), outPortHandle));
        outPortHandleVector = MatlabUtils.concat(outPortHandle{:});
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
            MatlabUtils.startsWith(x, 'sfix') ...
            || MatlabUtils.startsWith(x, 'ufix') ...
            || MatlabUtils.startsWith(x, 'fltu') ...
            || MatlabUtils.startsWith(x, 'flts'), compiledPortDT), 1);
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

