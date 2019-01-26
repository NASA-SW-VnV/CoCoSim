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
        
        %% add PP warning
        function add_pp_warning(model_path)
            if PPUtils.isAlreadyPP(model_path)
                warndlg('You are calling CoCoSim on the pre-processed model. Do not forget to make your modifications in the original model.');
            end
        end
        %% Create html page with title and items list.
        function html_path = createHtmlList(title, items_list, html_path)
            htmlList = cellfun(@(x) HtmlItem(x, {}, 'black', [], [], false),...
                items_list, 'UniformOutput', false);
            html_path = MenuUtils.createHtmlListUsingHTMLITEM(title, htmlList, html_path);
        end
        function html_path = createHtmlListUsingHTMLITEM(title, items_list, html_path, model)
            cocoSim_path = regexprep(mfilename('fullpath'), 'cocosim2/.+', 'cocosim2');
            css_source = fullfile(cocoSim_path, 'lib', 'materialize' , 'css' , 'materialize.css');
            html_text = fileread(fullfile(cocoSim_path, 'src', 'backEnd' , 'html_templates' , 'item_list.html'));
            html_text = strrep(html_text, '[css_source]', css_source);
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
        
        function metaInfo = getModelInfo(title, model)
            tableItemFormat = '<tr><td align="left">%s:</td><td align="left">%s</td></tr>';
            tableElts = {};
            
            % add model Name
            tableElts{end+1} = sprintf(tableItemFormat, ...
                'Model Path',...
                get_param(model, 'filename'));
            
            % add title
            tableElts{end+1} = sprintf(tableItemFormat, ...
                'Mode',...
                title);
            
            % add time
            tableElts{end+1} = sprintf(tableItemFormat, ...
                'Time Stamp',...
                datestr(now));
            
            metaInfo = MatlabUtils.strjoin(tableElts, '\n');
        end
    end
    
end

