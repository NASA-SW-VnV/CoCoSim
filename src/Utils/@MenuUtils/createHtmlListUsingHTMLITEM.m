function html_path = createHtmlListUsingHTMLITEM(title, items_list, html_path, model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [output_dir, ~, ~] = fileparts(html_path);
    if exist(html_path, 'file')
        delete(html_path);
    end
    if ~exist(output_dir, 'dir')
        MatlabUtils.mkdir(output_dir);
    end
    cocoSim_path = regexprep(mfilename('fullpath'), 'cocosim2/.+', 'cocosim2');
    % read template
    html_text = fileread(fullfile(cocoSim_path, 'src', 'backEnd' , 'html_templates' , 'item_list.html'));


    % copy css and js

    % this css file is modified from the original. Dont use the
    % minified version materialize.min.css
    materialize_path = fullfile(cocoSim_path, 'libs', 'materialize');
    css_source = fullfile(cocoSim_path, 'src', 'external', 'html_lib', 'materialize' , 'css' , 'materialize.css');
    js_source = fullfile(cocoSim_path, 'src', 'external', 'html_lib', 'materialize' , 'js' , 'materialize.min.js');
    if exist(materialize_path, 'dir')
        copyfile(materialize_path, output_dir);
    else
        css_online = 'href="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.100.2/css/materialize.min.css"';
        html_text = strrep(html_text, 'href="materialize.css"', css_online);
        js_online = 'src="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.100.2/js/materialize.min.js"';
        html_text = strrep(html_text, 'src="materialize.css"', js_online);
    end
    % add model Info
    if nargin == 4
        html_text = strrep(html_text, '[META_INFO]', MenuUtils.getModelInfo(title, model));
    else
        html_text = strrep(html_text, '[META_INFO]', '');
    end
    % update title
    html_text = strrep(html_text, '[TITLE]', title);
    %add Items text
    items_text = cell(numel(items_list), 1);
    if iscell(items_list)
        for i=1:numel(items_list)
            items_text{i} = items_list{i}.print();
        end
    else
        items_text{1} = items_list.print();
    end
    items_text = MatlabUtils.strjoin(items_text, '\n');
    html_text = strrep(html_text, '[List_Items]', items_text);

    % clean html
    html_text = regexprep(html_text, '%+', '%%');


    fid = fopen(html_path, 'w+');
    if ~strcmp(html_text, '')
        fprintf(fid, html_text);
        web(html_path, '-new');
    end
    fclose(fid);
end

