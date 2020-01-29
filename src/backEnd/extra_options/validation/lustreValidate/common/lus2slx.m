%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%LUS2SLX translate an EMF json file to Simulink blocks. Every node is translated
%to a subsystem. If OnlyMainNode is true than only the main node specified
%in main_node argument will be kept in the final simulink model.
function [status,...
    new_model_path, ...
    xml_trace] = lus2slx(...
    json_path, ...
    output_dir, ...
    new_model_name, ...
    main_node, ...
    organize_blocks,...
    force)

%% Init
bdclose('all');
[coco_dir, cocospec_name, ~] = fileparts(json_path);
if ~exist('main_node', 'var') || isempty(main_node)
    onlyMainNode = false;
else
    onlyMainNode = true;
end
if ~exist('organize_blocks', 'var') || isempty(organize_blocks)
    organize_blocks = false;
end
if ~exist('force', 'var') || isempty(force)
    force = true;
end
base_name = regexp(cocospec_name,'\.','split');
if ~exist('new_model_name', 'var') || isempty(new_model_name)
    if onlyMainNode
        new_model_name = BUtils.adapt_block_name(strcat(base_name{1}, '_', main_node));
    else
        new_model_name = BUtils.adapt_block_name(strcat(base_name{1}, '_emf'));
    end
end

%%
status = 0;
display_msg('Runing Lus2SLX on EMF file', MsgType.INFO, 'lus2slx', '');

if nargin < 2
    output_dir = coco_dir;
end

data = BUtils.read_json(json_path);

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

new_model_path = fullfile(output_dir,strcat(new_model_name,'.slx'));
xml_trace_file_name = fullfile(output_dir, ...
    strcat(cocospec_name, '.emf.trace.xml'));
json_trace_file_name = fullfile(output_dir, ...
    strcat(cocospec_name, '.emf.trace.json'));
xml_trace = nasa_toLustre.utils.SLX2Lus_Trace(new_model_path, xml_trace_file_name, json_trace_file_name);
xml_trace.init();
if exist(new_model_path,'file')
    if BUtils.isLastModified(json_path, new_model_path) && ~force
        msg = sprintf('lus2slx file "%s" already generated. It will be used.\n',new_model_path);
        display_msg(msg, MsgType.DEBUG, 'lus2slx', '');
        return;
    end
    if bdIsLoaded(new_model_name)
        close_system(new_model_name,0)
    end
    delete(new_model_path);
end
close_system(new_model_name,0);
model_handle = new_system(new_model_name);


% save_system(model_handle,new_name);

x = 200;
y = -50;

nodes = data.nodes;
emf_fieldnames = fieldnames(nodes)';
if onlyMainNode
%     nodes_names = arrayfun(@(x)  BUtils.adapt_block_name(x{1}),...
%         fieldnames(nodes)', 'UniformOutput', false);
    nodes_names = arrayfun(@(x)  nodes.(x{1}).original_name,...
        emf_fieldnames, 'UniformOutput', false);
    if ~ismember(main_node, nodes_names)
        msg = sprintf('Node "%s" not found in JSON "%s"', ...
            main_node, json_path);
        display_msg(msg, MsgType.ERROR, 'LUS2SLX', '');
        status = 1;
        new_model_path = '';
        close_system(new_model_name,0);
        xml_trace_file_name = '';
        return
    end
    node_idx = ismember(nodes_names, main_node);
    node_name = emf_fieldnames{node_idx};
    node_block_path = fullfile(new_model_name, BUtils.adapt_block_name(main_node));
    block_pos = [(x+100) y (x+250) (y+50)];
    Lus2SLXUtils.node_process(new_model_name, nodes, node_name, node_block_path, block_pos, xml_trace);
else
    for i = 1:length(emf_fieldnames)
        node = emf_fieldnames{i};
        try
            node_name = BUtils.adapt_block_name(node);
            display_msg(...
                sprintf('Processing node "%s" ',node_name),...
                MsgType.INFO, 'lus2slx', '');
            y = y + 150;

            block_pos = [(x+100) y (x+250) (y+50)];
            node_block_path = fullfile(new_model_name,node_name);
            Lus2SLXUtils.node_process(new_model_name, nodes, node, node_block_path, block_pos, []);
            
        catch ME
            display_msg(['couldn''t translate node ' node ' to Simulink'], MsgType.ERROR, 'LUS2SLX', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'LUS2SLX', '');
            %         continue;
            status = 1;
            return;
        end
    end
end

% fix issue of IF blocks inside Resettable subsystem, the block IF-Action
% should be forced to reset.
Lus2SLXUtils.AddResettableSubsystemToIfBlock(new_model_name);
% Remove From Goto blocks and organize the blocks positions
if organize_blocks
    goto_process( new_model_name );
    BlocksPosition_pp( new_model_name );
end
% Write traceability informations
xml_trace.write();
configSet = getActiveConfigSet(model_handle);
set_param(configSet, 'Solver', 'FixedStepDiscrete');
save_system(model_handle,new_model_path,'OverwriteIfChangedOnDisk',true);

% open_system(model_handle);
end
