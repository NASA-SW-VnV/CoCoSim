function [valid, sim_failed] = compareTwoSLXModels(orig_mdl_path, pp_mdl_path,...
        min_max_constraints, show_models)
    
    if nargin >= 3 && iscell(min_max_constraints) && numel(min_max_constraints) > 0
        IMIN = cellfun(@(x) x{2}, min_max_constraints);
        IMAX = cellfun(@(x) x{3}, min_max_constraints);
    else
        IMIN = -300;
        IMAX = 300;
    end
    
    if nargin < 4
        show_models = false;
    end
    valid = true;
    sim_failed = false;
    
    [orig_mdl_dir, orig_mdl_name, ~] = fileparts(orig_mdl_path);
    [~, pp_mdl_name, ~] = fileparts(pp_mdl_path);
    % Make sure Both models has same interface (Inports/Outports dimensions,
    % datatype)
    areTheSame = modelsAreTheSame(orig_mdl_path, pp_mdl_path);
    if ~areTheSame
        valid = 0;
        sim_failed = 1;
        return;
    end
    % Create the input struct for the simulation
    nb_steps = 100;
    
    eps = SLXUtils.getLustrescSlxEps(orig_mdl_path);
    [ input_dataSet ] = random_tests(orig_mdl_path, nb_steps, IMIN, IMAX );
    if ~isa(input_dataSet, 'Simulink.SimulationData.Dataset')
        msg = sprintf('Input Signals should be of class Simulink.SimulationData.Dataset');
        display_msg(msg, MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
        sim_failed = 1;
        return;
    end
    numberOfInports = numel(input_dataSet.getElementNames);
    if numberOfInports >= 1
        time = LustrecUtils.getTimefromDataset(input_dataSet);
        if isempty(time)
            msg = sprintf('Input Signals should be of class Simulink.SimulationData.Dataset');
            display_msg(msg, MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
            sim_failed = 1;
            return;
        end
    else
        st = SLXUtils.getModelCompiledSampleTime(orig_mdl_name);
        if st > 0
            time = (0:st:100)';
        else
            time = (0:0.1:100)';
        end
    end
    nb_steps = numel(time);
    if nb_steps >= 2
        simulation_step = time(2) - time(1);
    else
        simulation_step = 1;
    end
    stop_time = time(end);
    
    % Simulate the model
    try
        simOut1 = SLXUtils.simulate_model(orig_mdl_path, ...
            input_dataSet, ...
            simulation_step,...
            stop_time,...
            numberOfInports,...
            show_models);
        
        yout1 = get(simOut1,'yout');
        assignin('base', 'yout1', yout1);
        if isempty(yout1)
            f_msg = sprintf('Model "%s" has no Outport.',orig_mdl_name);
            display_msg(f_msg, MsgType.RESULT, 'SLXUtils.compareTwoSLXModels', '');
            sim_failed = 1;
            return;
        elseif ~isa(yout1, 'Simulink.SimulationData.Dataset')
            f_msg = sprintf('Model "%s" shoud use Simulink.SimulationData.Dataset save format.',orig_mdl_name);
            display_msg(f_msg, MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
            sim_failed = 1;
            return;
        end
        
        simOut2 = SLXUtils.simulate_model(pp_mdl_path, ...
            input_dataSet, ...
            simulation_step,...
            stop_time,...
            numberOfInports,...
            show_models);
        
        yout2 = get(simOut2,'yout');
        assignin('base', 'yout2', yout2);
        sim_failed  = 0;
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'SLXUtils.compareTwoSLXModels', '');
        display_msg('Simulation failed', MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
        sim_failed = 1;
        return;
    end
    numberOfOutputs = length(yout1.getElementNames);
    numberOfInports = length(input_dataSet.getElementNames);
    cex_msg = {};
    out_width = zeros(numberOfOutputs,1);
    for k=1:numberOfOutputs
        out_width(k) = LustrecUtils.getSignalWidth(yout1{k}.Values);
    end
    diff_name = '';
    diff_value = 0;
    for i=1:numel(time)
        cex_msg{end+1} = sprintf('*****time : %f**********\n',time(i));
        cex_msg{end+1} = sprintf('*****inputs: \n');
        for j=1:numberOfInports
            in = LustrecUtils.getSignalValuesInlinedUsingTime(input_dataSet{j}.Values, time(i));
            in_width = numel(in);
            name = input_dataSet{j}.Name;
            for jk=1:in_width
                cex_msg{end+1} = sprintf('input %s_%d: %f\n',name,jk,in(jk));
            end
        end
        cex_msg{end+1} = sprintf('*****outputs: \n');
        found_output = false;
        diff_value = 0;
        for k=1:numberOfOutputs
            yout1_values = LustrecUtils.getSignalValuesInlinedUsingTime(yout1{k}.Values, time(i));
            yout2_values = LustrecUtils.getSignalValuesInlinedUsingTime(yout2{k}.Values, time(i));
            if isempty(yout1_values) || isempty(yout2_values)
                % signal is not defined in the current timestep
                continue;
            elseif numel(yout1_values) ~= numel(yout2_values)
                % Signature is not the same
                valid = 0;
                sim_failed = 1;
                return;
            end
            found_output = true;
            for j=1:out_width(k)
                y1_value = double(yout1_values(j));
                y2_value = double(yout2_values(j));
                
                slx1_output_name =...
                    BUtils.naming_alone(yout1{k}.BlockPath.getBlock(1));
                cex_msg{end+1} = sprintf('%s Simulink output %s(%d): %10.16f\n',...
                    orig_mdl_name, slx1_output_name, j, y1_value);
                slx2_output_name =...
                    BUtils.naming_alone(yout2{k}.BlockPath.getBlock(1));
                cex_msg{end+1} = sprintf('%s Simulink output %s(%d): %10.16f\n',...
                    pp_mdl_name, slx2_output_name, j, y2_value);
                if isinf(y1_value) || isnan(y1_value)...
                        || isinf(y2_value) || isnan(y2_value)
                    diff=0;
                elseif abs(y1_value) > 10^10 && abs(y1_value-y2_value) > eps
                    diff = abs(y1_value-y2_value)/y1_value;
                else
                    diff = abs(y1_value-y2_value);
                end
                valid = valid && (diff<eps);
                if  (diff >= eps)
                    diff_name =  ...
                        BUtils.naming_alone(yout1{k}.BlockPath.getBlock(1));
                    diff_name =  strcat(diff_name, '(',num2str(j), ')');
                    diff_value = diff;
                    % don't break now untile this timestep finish displatyin all outputs
                    %break
                end
            end
        end
        if ~found_output
            cex_msg{end+1} = sprintf('No Output saved for this time step.\n');
        end
        if  ~valid
            break;
        end
        
    end
    
    if valid == 1
        f_msg = sprintf('Comparaison for model "%s" and model "%s" is  valid \n',...
            orig_mdl_name, pp_mdl_name);
        display_msg(f_msg, MsgType.RESULT, 'SLXUtils.compareTwoSLXModels', '');
    else
        %% show the counter example
        
        f_msg = sprintf('Comparaison for model "%s" and model "%s" is not valid \n',...
            orig_mdl_name, pp_mdl_name);
        display_msg(f_msg, MsgType.RESULT, 'SLXUtils.compareTwoSLXModels', '');
        f_msg = sprintf('Here is the counter example:\n');
        display_msg(f_msg, MsgType.RESULT, 'SLXUtils.compareTwoSLXModels', '');
        t = datetime('now','Format','dd-MM-yyyy''@''HHmmss');
        directory = fullfile(orig_mdl_dir, 'cocosim_output', 'orig_mdl_name');
        MatlabUtils.mkdir(directory);
        cex_file_path = fullfile(directory, strcat('cex_orig_vs_pp_', char(t), '.txt'));
        
        LustrecUtils.show_CEX(cex_msg, cex_file_path );
        f_msg = sprintf('The difference between outputs %s is :%2.10f\%\n',diff_name, diff_value);
        display_msg(f_msg, MsgType.RESULT, 'CEX', '');
    end
end



%%
function areTheSame = modelsAreTheSame(mdl1, mdl2)
    areTheSame = false;
    load_system(mdl1);
    load_system(mdl2);
    [~, mdl1_name, ~] = fileparts(mdl1);
    [~, mdl2_name, ~] = fileparts(mdl2);
    
    mdl1_inports = find_system(mdl1_name, 'SearchDepth', 1, 'BlockType', 'Inport');
    mdl2_inports = find_system(mdl2_name, 'SearchDepth', 1, 'BlockType', 'Inport');
    mdl1_outports = find_system(mdl1_name, 'SearchDepth', 1, 'BlockType', 'Outport');
    mdl2_outports = find_system(mdl2_name, 'SearchDepth', 1, 'BlockType', 'Outport');
    
    if length(mdl1_inports) ~= length(mdl2_inports) ...
            ||  length(mdl1_outports) ~= length(mdl2_outports)
        display_msg(sprintf('Models "%s" and "%s" do not have the same interface.',...
            mdl1_name, mdl2_name),...
            MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
        return;
    end
    % compare sample times
    [st1, ph1] = SLXUtils.getModelCompiledSampleTime(mdl1_name);
    [st2, ph2] = SLXUtils.getModelCompiledSampleTime(mdl2_name);
    if st1 ~= st2 || ph1 ~= ph2
        display_msg(sprintf('Models "%s" and "%s" do not have the same Sample Time. The first model has "[%f, %f]" where the second has "[%f, %f]".',...
            mdl1_name, mdl2_name, st1, ph1, st2, ph2),...
            MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
        return;
    end
    % compile both models
    try
        evalin('base',sprintf('%s([], [], [], ''compile'')', mdl1_name));
        evalin('base',sprintf('%s([], [], [], ''compile'')', mdl2_name));
        failed = false;
        for i=1:length(mdl1_inports)
            compiledPortDim1 = get_param(mdl1_inports{i}, 'CompiledPortDimensions');
            compiledPortDim2 = get_param(mdl2_inports{i}, 'CompiledPortDimensions');
            [r, dim1, dim2] = dimsAreEqual(compiledPortDim1.Outport, compiledPortDim2.Outport);
            if ~r
                display_msg(sprintf('Inports "%s" and "%s" do not have the same dimensions. First has dimension of %s where the second has a dimension of %s.',...
                    mdl1_inports{i}, mdl2_inports{i}, mat2str(dim1), mat2str(dim2)),...
                    MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
                failed = true;
                break;
            end
            CompiledPortDataType1 = get_param(mdl1_inports{i}, 'CompiledPortDataTypes');
            CompiledPortDataType2 = get_param(mdl1_inports{i}, 'CompiledPortDataTypes');
            if ~strcmp(CompiledPortDataType1.Outport{1}, CompiledPortDataType2.Outport{1})
                display_msg(sprintf('Inports "%s" and "%s" do not have the same dataTypes. First has datatype "%s" whereas the second has datatype of "%s"',...
                    mdl1_inports{i}, mdl2_inports{i}, ...
                    CompiledPortDataType1.Outport{1}, CompiledPortDataType2.Outport{1}),...
                    MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
                failed = true;
                break;
            end
        end
        if ~failed
            for i=1:length(mdl1_outports)
                compiledPortDim1 = get_param(mdl1_outports{i}, 'CompiledPortDimensions');
                compiledPortDim2 = get_param(mdl2_outports{i}, 'CompiledPortDimensions');
                [r, dim1, dim2] = dimsAreEqual(compiledPortDim1.Inport, compiledPortDim2.Inport);
                if ~r
                    display_msg(sprintf('Outports "%s" and "%s" do not have the same dimensions. First has dimension of %s where the second has a dimension of %s.',...
                        mdl1_outports{i}, mdl2_outports{i}, ...
                        mat2str(dim1), mat2str(dim2)),...
                        MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
                    failed = true;
                    break;
                end
                CompiledPortDataType1 = get_param(mdl1_outports{i}, 'CompiledPortDataTypes');
                CompiledPortDataType2 = get_param(mdl2_outports{i}, 'CompiledPortDataTypes');
                if ~strcmp(CompiledPortDataType1.Inport{1}, CompiledPortDataType2.Inport{1})
                    display_msg(sprintf('Outports "%s" and "%s" do not have the same dataTypes. First has datatype "%s" whereas the second has datatype of "%s"',...
                            mdl1_outports{i}, mdl2_outports{i}, ...
                            CompiledPortDataType1.Inport{1}, CompiledPortDataType2.Inport{1}),...
                            MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
                    if MatlabUtils.contains(CompiledPortDataType1.Inport{1}, 'fix') ... % fixed-point data type
                            || MatlabUtils.contains(CompiledPortDataType1.Inport{1}, 'flt') % scaled doubles
                        % ignore it,
                    else
                        failed = true;
                        break;
                    end
                end
            end
        end
        
        evalin('base',sprintf('%s([], [], [], ''term'')', mdl1_name));
        evalin('base',sprintf('%s([], [], [], ''term'')', mdl2_name));
        if failed
            return;
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'SLXUtils.compareTwoSLXModels', '');
        display_msg(sprintf('Comparing models "%s" and "%s" failed.',...
            mdl1_name, mdl2_name),...
            MsgType.ERROR, 'SLXUtils.compareTwoSLXModels', '');
        try
            evalin('base',sprintf('%s([], [], [], ''term'')', mdl1_name));
            evalin('base',sprintf('%s([], [], [], ''term'')', mdl2_name));
        catch
        end
        return;
    end
    
    % passed all tests
    areTheSame = true;
    
end

function [r, dim1, dim2] = dimsAreEqual(dim1, dim2)
    % remove first element that tells how many dimension the port has.
    dim1 = dim1(2:end);
    dim2 = dim2(2:end);
    if length(dim1) == length(dim2)
        r = all(dim1 == dim2);
    elseif length(dim1) == 1 &&  length(dim2) == 2
        r = ( (dim2(1)==1) && (dim2(2) == dim1(1))) ...
            || ((dim2(2)==1) && (dim2(1) == dim1(1)));
    elseif length(dim2) == 1 &&  length(dim1) == 2
        r = ( (dim1(1)==1) && (dim1(2) == dim2(1))) ...
            || ((dim1(2)==1) && (dim1(1) == dim2(1)));
    else
        r = false;
    end
end