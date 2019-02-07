classdef SLXUtils
    %SLXUtils Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        
        %% Try to calculate Block sample time using the model
        [st, ph, Clocks] = getModelCompiledSampleTime(file_name)
                
        %% get the value of a parameter
        [Value, valueDataType, status] = evalParam(modelObj, parent, blk, param)
        
        %% Get compiled params: CompiledPortDataTypes ...
        [res] = getCompiledParam(h, param)
        %% run constants files
        run_constants_files(const_files)

        %% Get percentage of tolerance from floiting values between lustrec and SLX
        eps = getLustrescSlxEps(model_path)
        %%
        [model_inputs_struct, inputEvents_names] = get_model_inputs_info(model_full_path)
        %%
        [isBus, bus] = isSimulinkBus(SignalName, model)
        %%
        min_max_constraints = constructInportsMinMaxConstraints(model_full_path, IMIN_DEFAULT, IMAX_DEFAULT)
        %% create random vector test
        [ds, simulation_step, stop_time] = ...
            get_random_test(slx_file_name, inports, nb_steps,IMAX, IMIN)

        Values = get_random_values(time, nb_steps, min, max, dim, dt)

        values = construct_random_bus_values(bus, time, nb_steps, min, max, dim)

        %% Simulate the model
        simOut = simulate_model(slx_file_name, ...
                input_dataset, ...
                simulation_step,...
                stop_time,...
                numberOfInports,...
                show_models)        
        %%
        [new_model_path, new_model_name, status] = ...
            crete_model_from_subsystem(file_name, ss_path, output_dir )
        
        %%        
        [new_model_name, status] = makeharness(T, subsys_path, output_dir, postfix_name)
        
        %%
        U_dims = tf_get_U_dims(model, pp_name, blkList)
        
        %%
        status = createSubsystemFromBlk(blk_path)
        
    end
    
end

