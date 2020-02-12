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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [valid, sim_failed, cex_file_path] = compareTwoSLXModels(orig_mdl_path, pp_mdl_path,...
        min_max_constraints, show_models)
    
    if ~exist('min_max_constraints', 'var') || isempty(min_max_constraints)
        min_max_constraints = coco_nasa_utils.SLXUtils.constructInportsMinMaxConstraints(orig_mdl_path, -300, 300);
    end
    if iscell(min_max_constraints) && numel(min_max_constraints) > 0
        IMIN = cellfun(@(x) x{2}, min_max_constraints);
        IMAX = cellfun(@(x) x{3}, min_max_constraints);
    else
        IMIN = -300;
        IMAX = 300;
    end
    
    if nargin < 4
        show_models = false;
    end
    valid = false;
    sim_failed = false;
    cex_file_path = '';
    if strcmp(orig_mdl_path, pp_mdl_path)
        valid = true;
        return;
    end
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
    
    eps = coco_nasa_utils.SLXUtils.getLustrescSlxEps(orig_mdl_path);
    [ input_dataSet ] = random_tests(orig_mdl_path, nb_steps, IMIN, IMAX );
    if ~isa(input_dataSet, 'Simulink.SimulationData.Dataset')
        msg = sprintf('Input Signals should be of class Simulink.SimulationData.Dataset');
        display_msg(msg, MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
        sim_failed = 1;
        return;
    end
    numberOfInports = numel(input_dataSet.getElementNames);
    if numberOfInports >= 1
        time = LustrecUtils.getTimefromDataset(input_dataSet);
        if isempty(time)
            msg = sprintf('Input Signals should be of class Simulink.SimulationData.Dataset');
            display_msg(msg, MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
            sim_failed = 1;
            return;
        end
    else
        st = coco_nasa_utils.SLXUtils.getModelCompiledSampleTime(orig_mdl_name);
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
    
    %% Simulate the model
    try
        simOut1 = coco_nasa_utils.SLXUtils.simulate_model(orig_mdl_path, ...
            input_dataSet, ...
            simulation_step,...
            stop_time,...
            numberOfInports,...
            show_models);
        
        yout1 = get(simOut1,'yout');
        assignin('base', 'yout1', yout1);
        if isempty(yout1)
            f_msg = sprintf('Model "%s" has no Outport.',orig_mdl_name);
            display_msg(f_msg, MsgType.RESULT, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
            sim_failed = 1;
            return;
        elseif ~isa(yout1, 'Simulink.SimulationData.Dataset')
            f_msg = sprintf('Model "%s" shoud use Simulink.SimulationData.Dataset save format.',orig_mdl_name);
            display_msg(f_msg, MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
            sim_failed = 1;
            return;
        end
        
        simOut2 = coco_nasa_utils.SLXUtils.simulate_model(pp_mdl_path, ...
            input_dataSet, ...
            simulation_step,...
            stop_time,...
            numberOfInports,...
            show_models);
        
        yout2 = get(simOut2,'yout');
        assignin('base', 'yout2', yout2);
        sim_failed  = 0;
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
        display_msg('Simulation failed', MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
        sim_failed = 1;
        return;
    end
    
    %% compare both outputs
    [valid, cex_msg, diff_name, diff_value, sim_failed] = ...
        LustrecUtils.compare_slx_out_with_lusORslx_out(...
        input_dataSet, ...
        yout1,...
        yout2, ...
        [], ...
        eps, ...
        time);

    
    if valid == 1
        f_msg = sprintf('Pre-Processing Validation: Comparaison for model "%s" and model "%s" is  valid \n',...
            orig_mdl_name, pp_mdl_name);
        display_msg(f_msg, MsgType.RESULT, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
    else
        %% show the counter example
        
        f_msg = sprintf('Pre-Processing Validation: Comparaison for model "%s" and model "%s" is not valid \n',...
            orig_mdl_name, pp_mdl_name);
        display_msg(f_msg, MsgType.RESULT, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
        f_msg = sprintf('Here is the counter example:\n');
        display_msg(f_msg, MsgType.RESULT, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
        t = datetime('now','Format','dd-MM-yyyy''@''HHmmss');
        directory = fullfile(orig_mdl_dir, 'cocosim_output', 'orig_mdl_name');
        coco_nasa_utils.MatlabUtils.mkdir(directory);
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
            MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
        return;
    end
    % compare sample times
    [st1, ph1] = coco_nasa_utils.SLXUtils.getModelCompiledSampleTime(mdl1_name);
    [st2, ph2] = coco_nasa_utils.SLXUtils.getModelCompiledSampleTime(mdl2_name);
    if st1 ~= st2 || ph1 ~= ph2
        display_msg(sprintf('Models "%s" and "%s" do not have the same Sample Time. The first model has "[%f, %f]" where the second has "[%f, %f]".',...
            mdl1_name, mdl2_name, st1, ph1, st2, ph2),...
            MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
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
                    MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
                failed = true;
                break;
            end
            CompiledPortDataType1 = get_param(mdl1_inports{i}, 'CompiledPortDataTypes');
            CompiledPortDataType2 = get_param(mdl1_inports{i}, 'CompiledPortDataTypes');
            if ~strcmp(CompiledPortDataType1.Outport{1}, CompiledPortDataType2.Outport{1})
                display_msg(sprintf('Inports "%s" and "%s" do not have the same dataTypes. First has datatype "%s" whereas the second has datatype of "%s"',...
                    mdl1_inports{i}, mdl2_inports{i}, ...
                    CompiledPortDataType1.Outport{1}, CompiledPortDataType2.Outport{1}),...
                    MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
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
                        MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
                    failed = true;
                    break;
                end
                CompiledPortDataType1 = get_param(mdl1_outports{i}, 'CompiledPortDataTypes');
                CompiledPortDataType2 = get_param(mdl2_outports{i}, 'CompiledPortDataTypes');
                if ~strcmp(CompiledPortDataType1.Inport{1}, CompiledPortDataType2.Inport{1})
                    display_msg(sprintf('Outports "%s" and "%s" do not have the same dataTypes. First has datatype "%s" whereas the second has datatype of "%s"',...
                            mdl1_outports{i}, mdl2_outports{i}, ...
                            CompiledPortDataType1.Inport{1}, CompiledPortDataType2.Inport{1}),...
                            MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
                    if coco_nasa_utils.MatlabUtils.contains(CompiledPortDataType1.Inport{1}, 'fix') ... % fixed-point data type
                            || coco_nasa_utils.MatlabUtils.contains(CompiledPortDataType1.Inport{1}, 'flt') % scaled doubles
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
        display_msg(me.getReport(), MsgType.DEBUG, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
        display_msg(sprintf('Comparing models "%s" and "%s" failed.',...
            mdl1_name, mdl2_name),...
            MsgType.ERROR, 'coco_nasa_utils.SLXUtils.compareTwoSLXModels', '');
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