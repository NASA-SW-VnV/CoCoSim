function makeSumsRectangular(blocks)
% MAKESUMSRECTANGULAR Change the shape of sum blocks to be rectangular.
%
%   Inputs:
%       blocks  Cell array of blocks. Non-Sum blocks will not be affected.
%
%   Outputs:
%       N/A

    for i = 1:length(blocks)
        if strcmp(get_param(blocks{i},'BlockType'), 'Sum') % Check if Sum
            % Change to shape to be rectangular
            set_param(blocks{i},'IconShape', 'rectangular');
            % Remove spacers (|). They manipulate the positions of the input ports
            signs = strrep(get_param(blocks{i}, 'ListOfSigns'), '|', '');
            set_param(blocks{i}, 'ListOfSigns', signs);
        end
    end
end