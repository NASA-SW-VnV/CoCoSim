function [results, passed] = jc_0081(model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ORION GN&C MATLAB/Simulink Standards
% jc_0081: Icon display for Port block
results = {};
title = 'jc_0081: Icon display for Port block';

% For IconDisplay there are 3 options:
%      'Signal name' | {'Port number'} | 'Port number and signal name'
% only 'Port number' number is correct
portBlocks = find_system(model,'Regexp', 'on','blocktype','port', 'IconDisplay','name');
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


