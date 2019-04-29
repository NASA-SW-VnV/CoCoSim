function res = print(obj, level)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~exist('level', 'var')
        level = 4;
    end
    if isempty(obj.text_color)
        Textcolor = obj.colorMap(level);
    else
        Textcolor = obj.text_color;
    end

    if strcmp(obj.icon_color, 'red')
            iconCode = sprintf('<i class="material-icons red-text"><h%d>do_not_disturb_on<h%d></i>', level, level);
    elseif strcmp(obj.icon_color, 'green')
        iconCode = sprintf('<i class="material-icons green-text"><h%d>check_circle<h%d></i>', level, level);
    else
        iconCode = '';
    end            

    %             if isempty(obj.subtitles)
    dropDownCode = '';
    %             else
    %                 dropDownCode = sprintf('<i class="material-icons black-text"><h%d>arrow_drop_down<h%d></i>', level, level);
    %             end
    header =  sprintf('<div class="collapsible-header">%s<div class="%s-text text-darken-2"><h%d>%s</h%d></div>%s</div>\n', ...
        iconCode, Textcolor,level, obj.title, level, dropDownCode);
    if isempty(obj.subtitles)
        res = sprintf('<li>\n%s\n</li>', header);
    else
        res = sprintf('<li>\n%s\n<div class="collapsible-body">\n<div class="row">\n<div class="col s12 m12">\n<ul class="collapsible" >\n', ...
            header);
        for i=1:numel(obj.subtitles)
            res = [res ' ' obj.subtitles{i}.print(level + 1)];
        end
        res = [res, ' </ul>\n</div>\n</div>\n</div>\n</li>'];
    end
end

