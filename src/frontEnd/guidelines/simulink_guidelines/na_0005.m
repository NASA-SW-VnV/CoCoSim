function [results, passed] = na_0005(model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ORION GN&C MATLAB/Simulink Standards
% na_0005: Port block name visibility in Simulink models
results = {};
title = 'na_0005: Port block name visibility in Simulink models';

portBlocks = find_system(model,'Regexp', 'on','blocktype','port', 'ShowName','off');
passed = isempty(portBlocks);

resultList = cell(length(portBlocks), 1);
for i=1:length(portBlocks)
    resultList{i} = HtmlItem(portBlocks{i},{},'red');
end

if passed
    resultList{1} = HtmlItem('PASS', {},'green');
end

results{end+1} = HtmlItem(title, resultList,'black');

end


