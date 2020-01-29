%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright � 2020 United States Government as represented by the 
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function html_path = createHtmlListUsingHTMLITEM(title, items_list, html_path, model)
    
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
    materialize_path = fullfile(cocoSim_path, 'src', 'external', 'html_lib', 'materialize');
    %css_source = fullfile(cocoSim_path, 'src', 'external', 'html_lib', 'materialize' , 'css' , 'materialize.css');
    %js_source = fullfile(cocoSim_path, 'src', 'external', 'html_lib', 'materialize' , 'js' , 'materialize.min.js');
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

