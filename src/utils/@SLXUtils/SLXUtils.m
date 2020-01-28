%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
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
        
        %% export models to other Simulink older releases
        exportModelsTo(folder_Path, version);
        
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
        
        values = get_random_values_InTimeSeries(time, min, max, dim, dt)
        Values = get_random_values(nb_steps, min, max, dim, dt)
        
        %% Simulate the model
        simOut = simulate_model(slx_file_name, ...
            input_dataset, ...
            simulation_step,...
            stop_time,...
            numberOfInports,...
            show_models)
        %% terminate simulation if the model is in compile mode
        terminate(modelName)
        
        %% compare two models
        [valid, sim_failed, cex_file_path] = compareTwoSLXModels(orig_mdl_path, pp_mdl_path, min_max_constraints, show_models)
        %%
        [new_model_path, new_model_name, status] = ...
            crete_model_from_subsystem(file_name, ss_path, output_dir )
        
        %%
        [new_model_name, status] = makeharness(T, subsys_path, output_dir, postfix_name)
        
        %%
        U_dims = tf_get_U_dims(model, pp_name, blkList)
        
        %%
        status = createSubsystemFromBlk(blk_path)
        
        %%
        removeBlocksLinkedToMe(bHandle, removeMe)
        
    end
    
end

