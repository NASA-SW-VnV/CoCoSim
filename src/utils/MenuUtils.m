%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef MenuUtils
    %MenuUtils contains functions common to Menu functions
    
    properties
    end
    
    methods (Static = true)
        
        
        %% get function handle from its path
        function handle = funPath2Handle(fullpath)
            oldDir = pwd;
            [dirname,funName,~] = fileparts(which(fullpath));
            cd(dirname);
            handle = str2func(funName);
            cd(oldDir);
        end
        
        %% get file name from the current opened Simulink model.
        function [fpath, fname] = get_file_name(gcs)
            fname = bdroot(gcs);
            fpath = get_param(fname,'FileName');
        end
        
        %% Create html page with title and items list.
        function html_path = createHtmlList(title, items_list, html_path)
            cocoSim_path = regexprep(mfilename('fullpath'), 'cocosim2/.+', 'cocosim2');
            css_source = fullfile(cocoSim_path, 'lib', 'materialize' , 'css' , 'materialize.css');
            html_text = fileread(fullfile(cocoSim_path, 'src', 'backEnd' , 'html_templates' , 'item_list.html'));
            html_text = strrep(html_text, '[css_source]', css_source);
            % update title
            html_text = strrep(html_text, '[TITLE]', title);
            %add Items text
            library_item_template = '<a class="collection-item"><div class="blue-text text-darken-2">[Item]</div></a>';
            items_text = '';
            if iscell(items_list)
                for i=1:numel(items_list)
                    code = strrep(library_item_template, '[Item]', items_list{i});
                    items_text = [items_text, '\n', code];
                end
            else
                items_text = strrep(library_item_template, '[Item]', items_list);
            end
            html_text = strrep(html_text, '[List_Items]', items_text);
            [output_dir, ~, ~] = fileparts(html_path);
            if exist(html_path, 'file')
                delete(html_path);
            end
            if ~exist(output_dir, 'dir')
                MatlabUtils.mkdir(output_dir);
            end
            fid = fopen(html_path, 'w+');
            if ~strcmp(html_text, '')
                fprintf(fid, html_text);
                open(html_path);
            end
            fclose(fid);
        end
    end
    
end

