function [valid, validation_compute,lustrec_failed, ...
    lustrec_binary_failed, sim_failed, lus_file_path] = ...
    validate_ToLustre(model_full_path, tests_method, model_checker, ...
    show_model, deep_CEX, min_max_constraints, options)


validation_start = tic;

valid = -1;
lustrec_failed = -1;
lustrec_binary_failed= -1;
sim_failed = -1;
validation_compute = -1;
lus_file_path = '';
%close all simulink models
bdclose('all')
%% define parameters if not given by the user
if nargin < 3
    show_model = 0;
elseif show_model
    open(model_full_path);
end
if ~exist('min_max_constraints', 'var') || isempty(min_max_constraints)
    min_max_constraints = [];
end

if ~exist('deep_CEX', 'var') || isempty(deep_CEX)
    deep_CEX = 0;
end
if ~exist('tests_method', 'var') || isempty(tests_method)
    tests_method = 1;
end
if ~exist('model_checker', 'var') || isempty(model_checker)
    model_checker = 'KIND2'; 
end
if ~exist('options', 'var') || isempty(options)
    options = '';
end


[model_path, file_name, ext] = fileparts(char(model_full_path));
addpath(model_path);
%% generate lustre code
try
    f_msg = sprintf('Compiling model "%s" to Lustre\n',file_name);
    display_msg(f_msg, MsgType.RESULT, 'validation', '');
    GUIUtils.update_status('Runing CocoSim');
    [lus_file_path, xml_trace] = ToLustre(model_full_path, [], [], options);
%     lus_file_path = lustre_compiler(model_full_path);
    [output_dir, lus_file_name, ~] = fileparts(lus_file_path);
    file_name = lus_file_name;
    main_node = lus_file_name;
    model_full_path = fullfile(model_path,strcat(file_name,ext));
    if show_model
        open(model_full_path);
    end
    
catch ME
    msg = sprintf('Translation Failed for model "%s" :\n%s\n%s',...
        file_name,ME.identifier,ME.message);
    display_msg(msg, MsgType.ERROR, 'validation', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
    return;
end

%% for data types
% no need in new compiler
% BUtils.force_inports_DT(file_name);
%% launch validation

try
    [valid, lustrec_failed, lustrec_binary_failed, sim_failed] = ...
        compare_slx_lus(model_full_path, lus_file_path, main_node, ...
        output_dir, tests_method, model_checker, show_model,...
        min_max_constraints, options);
catch ME
    display_msg(ME.message, MsgType.ERROR, 'validation', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
    return;
end


if ~lustrec_failed && ~sim_failed && ~lustrec_binary_failed && ~valid && (deep_CEX > 0)
    validate_componentsV2(model_full_path, file_name, file_name, output_dir, ...
        deep_CEX, tests_method, model_checker, show_model, min_max_constraints, options);
    %     validate_components(model_full_path, file_name, file_name, ...
    % lus_file_path, xml_trace, output_dir, deep_CEX, 1, tests_method,...
    %     model_checker, show_model, min_max_constraints);
end


% close_system(model_full_path,0);
% bdclose('all')

if sim_failed==1
    validation_compute = -1;
else
    validation_compute = toc(validation_start);
end
end

%%
function validate_componentsV2(file_path, file_name, block_path, output_dir, ...
    deep_CEX, tests_method, model_checker, show_model, min_max_constraints, options)
% This version re-translate the subsystem to Lustre and does not take
% advantage from traceability. Because the lustre generated has additional
% inputs (like _timpe_step) so the signature of the lustre node is
% different from the Subsystem.
ss = find_system(block_path, 'SearchDepth',1, 'BlockType','SubSystem');
[~, mdl_name, ~] = fileparts(file_path);
if numel(ss) == 1
    ss = find_system(ss{1}, 'SearchDepth',1, 'BlockType','SubSystem');
    ss = ss(2:end);
end
for i=1:numel(ss)
    if strcmp(ss{i}, block_path)
        continue;
    end
    display_msg(['Validating SubSystem ' ss{i}], MsgType.INFO, 'validation', '');
    if ~bdIsLoaded(mdl_name),load_system(file_path);end
    [new_model_path, ~, status] = SLXUtils.crete_model_from_subsystem(file_name, ss{i}, output_dir );
    if status
        continue;
    end
    try
        valid = validate_ToLustre(new_model_path, tests_method, model_checker, ...
            show_model, deep_CEX-1, min_max_constraints, options);
        if valid == 0
            display_msg(['SubSystem ' ss{i} ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
        elseif valid == 1
            display_msg(['SubSystem ' ss{i} ' is valid'], MsgType.RESULT, 'validation', '');
        elseif valid == -1
            display_msg(['Validation of ' ss{i} ' has failed'], MsgType.RESULT, 'validation', '');
        end
    catch ME
        display_msg(ME.message, MsgType.ERROR, 'validation', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
        rethrow(ME);
    end
    
end

end

%%
function validate_components(file_path,file_name,block_path,  lus_file_path, xml_trace, output_dir, deep_CEX, deep_current, tests_method, model_checker, show_model, min_max_constraints)
ss = find_system(block_path, 'SearchDepth',1, 'BlockType','SubSystem');
if ~exist('deep_current', 'var')
    deep_current = 1;
end
for i=1:numel(ss)
    if strcmp(ss{i}, block_path)
        continue;
    end
    display_msg(['Validating SubSystem ' ss{i}], MsgType.INFO, 'validation', '');
    node_name = SLX2Lus_Trace.get_lustre_node_from_Simulink_block_name(xml_trace.getTraceRootNode(), ss{i});
    if ~strcmp(node_name, '')
        [new_model_path, ~, status] = SLXUtils.crete_model_from_subsystem(file_name, ss{i}, output_dir );
        if status
            continue;
        end
        try
            [valid, ~, ~, ~] = compare_slx_lus(new_model_path, lus_file_path, node_name, output_dir, tests_method, model_checker, show_model, min_max_constraints);
            if ~valid
                display_msg(['SubSystem ' ss{i} ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
                load_system(file_path);
                validate_components(file_path, file_name, ss{i}, lus_file_path, xml_trace, output_dir, deep_CEX, deep_current+1, tests_method, model_checker, show_model, min_max_constraints);
                if deep_current > deep_CEX; return;end
            else
                display_msg(['SubSystem ' ss{i} ' is valid'], MsgType.RESULT, 'validation', '');
            end
        catch ME
            display_msg(ME.message, MsgType.ERROR, 'validation', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
            rethrow(ME);
        end
    else
        display_msg(['No node for subsytem ' ss{i} ' is found'], MsgType.INFO, 'validation', '');
    end
end

end


