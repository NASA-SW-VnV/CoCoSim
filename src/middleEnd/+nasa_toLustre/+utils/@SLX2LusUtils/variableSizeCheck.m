%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function htmlItemMsg = variableSizeCheck(model_name)
    htmlItemMsg = '';
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
    code_off=sprintf('%s([], [], [], ''term'')', model_name);
    evalin('base',code_off);
    idx = find(cellfun(@(x) sum(x), varSize), 1);
    if ~isempty(idx)
        blk_name = get_param(outPortHandleVector(idx), 'Parent');
        msg = sprintf('Your model has many signals with variable size (e.g. Block %s output signal). CoCoSim does not support models with variable size signals.',...
            HtmlItem.addOpenCmd(blk_name));
        htmlItemMsg = HtmlItem(msg, {}, 'black');
    end
end

